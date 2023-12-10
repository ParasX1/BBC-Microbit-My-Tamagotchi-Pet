.syntax unified
.global main
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_EVENTS_IN2, 0x40006108
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514
.set GPIOTE_CONFIG2, 0x40006518

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100

.type main, %function
main:
  @ 0: init leds
  bl init_leds

  @ 1: Configure GPIOTE_CONFIG[0]
  @ Need to setup: mode, pin, port, polarity in the configuration register for GPIOTE[0]
  @ Section 6.9.4.8 in nRF52833 reference manual
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 1 (LoToHi)

  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  ldr r0, =GPIOTE_CONFIG1
  ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  ldr r0, =GPIOTE_CONFIG2
  ldr r1, =(1|4 << 8| 1 << 13 | 1 << 16) 
  str r1, [r0]

  @ 2: Enable Interrupt for GPIOTE[0] (id = 6)
  @ S6.9.4.6 in nRF52833 reference manual

  ldr r0, =GPIOTE_INTENSET
  ldr r1, = 0b111
  str r1, [r0]

  @ 3: enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual

  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  b MainLoop
.size main, .-main

MainLoop:
  ldr r0, =ageCounter  @If age of dog is too long it dies
  ldr r1, [r0]
  cmp r1, 0 @max age of dog 900 seconds basically
  IT EQ
  beq dogIsDead

  ldr r0, =stats  @If happiness hits 0, it dies
  ldr r1, [r0, 8]
  cmp r1, 0 @max age of dog 900 seconds basically
  IT EQ
  beq dogIsDead

  ldr r0, =stats  @If too little excersize it dies
  ldr r1, [r0]
  cmp r1, 0 @max age of dog 900 seconds basically
  IT EQ
  beq dogIsDead

  ldr r0, =stats  @If age of hunger = 0 it dies
  ldr r1, [r0,4]
  cmp r1, 0 @max age of dog 900 seconds basically
  IT EQ
  beq dogIsDead

  ldr r0, =stats  @If hunger = 10 it dies too fat
  ldr r1, [r0,4]
  cmp r1, 10 @max age of dog 900 seconds basically
  IT EQ
  beq dogIsDead

  ldr r0, =stats  @If dog has good health/excersize it gets a extra 10 "days"
  ldr r1, [r0]
  cmp r1, 10 @max age of dog 900 seconds basically
  IT EQ
  bleq dogLifeExtension

  ldr r0, =stats  @If dog is happy it gets a extra 10 "days" Headpats
  ldr r1, [r0,8]
  cmp r1, 10 @max age of dog 900 seconds basically then gets extended
  IT EQ
  bleq dogLifeExtension

  ldr r0, =actionState  
  ldr r1, [r0]
  cmp r1, 1 
  IT EQ
  bleq displayExercise

  ldr r0, =actionState  
  ldr r1, [r0,4]
  cmp r1, 1 
  IT EQ
  bleq displayFood

  ldr r0, =actionState  
  ldr r1, [r0,8]
  cmp r1, 1 
  IT EQ
  bleq displayHeadPat
  

  bl LoopPictureDog
  bl decrement_counter

b MainLoop

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  @ setup a breakpoint here to check when the interrupt occurs.
  @ interrupt code goes here
  @ clear event
  push {lr}

  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1,[r0]
  ldr r0, =ageCounter
  cmp r1,1
  ITTTT EQ
  ldreq r1,[r0]
  subeq r1,1 @reduce life counter by 1
  streq r1,[r0]
  bleq updateStatsExcercise

  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]

  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1,[r0]
  cmp r1,1
  ldr r0, =ageCounter @eating needs 2 age counter
  cmp r1,1
  ITTTT EQ
  ldreq r1,[r0,4]
  subeq r1,1 @reduce life counter by 1
  streq r1,[r0,4]
  bleq updateStatsFood @feed

  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1, =0
  str r1, [r0]

  ldr r0, =GPIOTE_EVENTS_IN2
  ldr r1,[r0]
  ldr r0, =ageCounter
  cmp r1,1
  ITTTT EQ
  ldreq r1,[r0, 8]
  subeq r1,1 @reduce life counter by 1
  streq r1,[r0, 8]
  bleq updateStatsHeadPat

  @clearing the handle for Button C
  ldr r0, =GPIOTE_EVENTS_IN2
  mov r2, 0
  str r2, [r0]
  nop

  pop {lr}
bx lr
///If value at GPIOTE_EVENTS_IN0 is 1 button a was pressed.
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

@----------------------------------------------------------------------------------------------------------------
@Important functions

updateStatsExcercise:
  ldr r0,=actionState
  ldr r1, [r0]
  mov r1, 1
  str r1,[r0]
bx lr

updateStatsFood:
  ldr r0,=actionState
  ldr r1, [r0,4]
  mov r1, 1
  str r1,[r0,4]
bx lr

updateStatsHeadPat:
  ldr r0,=actionState
  ldr r1, [r0,8]
  mov r1, 1
  str r1,[r0,8]
bx lr

updateStatsExcercise2:
  ldr r0,=actionState
  ldr r1, [r0]
  mov r1, 0
  str r1,[r0]
bx lr

updateStatsFood2:
  ldr r0,=actionState
  ldr r1, [r0,4]
  mov r1, 0
  str r1,[r0,4]
bx lr

updateStatsHeadPat2:
  ldr r0,=actionState
  ldr r1, [r0,8]
  mov r1, 0
  str r1,[r0,8]
bx lr

off:
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]

  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1, =0
  str r1, [r0]
bx lr

dogLifeExtension: @extends
  push {lr}
  ldr r0,=stats
  ldr r1, [r0]
  sub r1, 9
  str r1,[r0]
  ldr r0,=ageCounter
  ldr r1, [r0]
  add r1, 10
  str r1,[r0]
  pop {lr}
bx lr

excerciseUpdate: @adds 2 excercise points  - 1 hunger to do excersize ofc
  push {lr}
  ldr r0,=stats @add 2 ex points
  ldr r1, [r0]
  add r1, 2
  str r1,[r0]
  ldr r0,=stats @minus 1 hunger/health
  ldr r1, [r0,4]
  sub r1, 1
  str r1,[r0,4]
  ldr r0,=stats @ add 2 happiness
  ldr r1, [r0,4]
  add r1, 2
  str r1,[r0,4]
  pop {lr}
bx lr

foodUpdate: @adds 2 to health aka getting fat 
  push {lr}
  ldr r0,=stats @adds 2 health
  ldr r1, [r0,4]
  add r1, 2
  str r1,[r0,4]
  ldr r0,=stats @eating is boring
  ldr r1, [r0,8]
  sub r1, 1
  str r1,[r0,8]
  pop {lr}
bx lr

decrement_counter: @decrements age counter (reverse) by 1
  push {lr}
  ldr r0,=ageCounter
  ldr r1, [r0]
  sub r1,1
  str r1,[r0]
  pop {lr}
bx lr

dogIsDead:  @played if dog is dead
  push {lr}
  ldr r1,=0
  str r1,[r0]
  ldr r0, =stats
  mov r1,0
  str r1, [r0] @reset values health and excercise
  str r1, [r0,4]
  b LoopDeadDog @dog has died and game over  :(
  pop {lr}
bx lr

displayPicture:
  push {lr}
  mov r0,r4  @ row which is changed after looping
  ldr r1,=OFS_GPIO_OUT
  mov r2,1  @turning on row
  bl write_row_pin
  ldr r0, [r5], 4  @offsetting and going to the next line in memory
  ldr r1,=OFS_GPIO_OUT
  mov r2,1 @turning on coloumn pins
  bl write_column_pins
  adds r4, 1   @Moves r4 to next row value
  adds r6, 1   @moves loop once more
  bl timer @delayE between each row
  mov r0, 0b00000 @clearn
  bl write_row_pins @ resets picture
  pop {lr}
bx lr
@----------------------------------------------------------------------------------------------------------------

LoopPictureDog: @base loop for dog picture
  push {lr}
  bl dog_picture_1_second
  bl timer
  bl dog_picture_2_second
  bl timer
  bl dog_picture_1_second
  bl timer
  bl dog_picture_2_second
  bl timer
  pop {lr}
bx lr

LoopDeadDog:
  push {lr}
  bl dead_dog_picture_1_second
  bl big_timer
  bl dead_dog_picture_2_second
  bl big_timer
  b LoopDeadDog
  pop {lr}
bx lr

displayHeadPat:
  push {lr}
  bl updateStatsHeadPat2
  bl headPat_picture_1_second
  bl timer
  bl headPat_picture_1_second
  bl timer
  bl headPat_picture_2_second
  bl timer
  bl headPat_picture_3_second
  bl timer
  bl headPat_picture_4_second
  bl timer
  bl headPat_picture_3_second
  bl timer
  bl headPat_picture_2_second
  bl timer
  bl food_picture_9_second
  bl timer
  bl food_picture_10_second
  bl timer
  
  pop {lr}
bx lr

displayExercise: @Exercise led stiff
  push {lr}
  bl updateStatsExcercise2
  bl tree_picture_1_second
  bl timer
  bl tree_picture_2_second
  bl timer
  bl tree_picture_3_second
  bl timer
  bl tree_picture_4_second
  bl timer
  bl tree_picture_5_second
  bl timer
  bl tree_picture_6_second
  bl timer
  bl tree_picture_5_second
  bl timer
  bl tree_picture_4_second
  bl timer
  bl tree_picture_3_second
  bl timer
  bl tree_picture_2_second
  bl timer
  bl tree_picture_1_second
  bl timer
  bl decrement_counter @by 1 more
  nop
  bl excerciseUpdate @updates values based on actvity
  bl off
  pop {lr}
bx lr

displayFood: @Food led stiff
  push {lr}
  bl updateStatsFood2
  bl food_picture_1_second
  bl timer
  bl food_picture_2_second
  bl timer
  bl food_picture_3_second
  bl timer
  bl food_picture_4_second
  bl timer
  bl food_picture_5_second
  bl timer
  bl food_picture_6_second
  bl timer
  bl food_picture_7_second
  bl timer
  bl food_picture_8_second
  bl timer
  bl food_picture_9_second
  bl timer
  bl food_picture_10_second
  bl timer

  bl decrement_counter
  bl foodUpdate @updates values based on actvity

  bl off
  pop {lr}
bx lr


dog_picture_1_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop1
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop1:
  cmp r6, 300  @number of repeats
  bge exit_loop1  @exit loop
  push {lr}
  bl displayDogImage1 @does this
  pop {lr}
  b loop1
exit_loop1:
bx lr

displayDogImage1:
  push {lr}
  mov r4,0 @rows
  ldr r5, =dogPicture @address for dict
  bl picture_display_loop1
  mov r5,0
  pop {lr}
bx lr

picture_display_loop1:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop1  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b picture_display_loop1  @re entering loop
  exit_picture_display_loop1:
bx lr



dog_picture_2_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop2
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop2:
  cmp r6, 300  @number of repeats
  bge exit_loop2  @exit loop
  push {lr}
  bl displayDogImage2 @does this
  pop {lr}
  b loop2
exit_loop2:
bx lr

displayDogImage2:
  push {lr}
  mov r4,0 @rows
  ldr r5, =dogPicture2 @address for dict
  bl picture_display_loop2
  mov r5,0
  pop {lr}
bx lr

picture_display_loop2:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop2  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b picture_display_loop2  @re entering loop
  exit_picture_display_loop2:
bx lr



dead_dog_picture_1_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop3
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop3:
  cmp r6, 500  @number of repeats
  bge exit_loop3  @exit loop
  push {lr}
  bl deadDisplayDogImage1 @does this
  pop {lr}
  b loop3
exit_loop3:
bx lr

deadDisplayDogImage1:
  push {lr}
  mov r4,0 @rows
  ldr r5, =deadDogPicture1 @address for dict
  bl dead_picture_display_loop1
  mov r5,0
  pop {lr}
bx lr

dead_picture_display_loop1:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop3  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b dead_picture_display_loop1  @re entering loop
  exit_picture_display_loop3:
bx lr

dead_dog_picture_2_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop4
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop4:
  cmp r6, 500  @number of repeats
  bge exit_loop4  @exit loop
  push {lr}
  bl deadDisplayDogImage2 @does this
  pop {lr}
  b loop4
exit_loop4:
bx lr

deadDisplayDogImage2:
  push {lr}
  mov r4,0 @rows
  ldr r5, =deadDogPicture2 @address for dict
  bl dead_picture_display_loop2
  mov r5,0
  pop {lr}
bx lr

dead_picture_display_loop2:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop4  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b dead_picture_display_loop2  @re entering loop
  exit_picture_display_loop4:
bx lr

@-----------------------------------------------------------------------------------------------------

tree_picture_1_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop5
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop5:
  cmp r6, 500  @number of repeats
  bge exit_loop5  @exit loop
  push {lr}
  bl displayTreeImage1 @does this
  pop {lr}
  b loop5
exit_loop5:
bx lr

displayTreeImage1:
  push {lr}
  mov r4,0 @rows
  ldr r5, =treePicture @address for dict
  bl tree_picture_display_loop1
  mov r5,0
  pop {lr}
bx lr

tree_picture_display_loop1:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop5  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b tree_picture_display_loop1  @re entering loop
  exit_picture_display_loop5:
bx lr



tree_picture_2_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop6
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop6:
  cmp r6, 500  @number of repeats
  bge exit_loop6  @exit loop
  push {lr}
  bl displayTreeImage2 @does this
  pop {lr}
  b loop6
exit_loop6:
bx lr

displayTreeImage2:
  push {lr}
  mov r4,0 @rows
  ldr r5, =treePicture2 @address for dict
  bl tree_picture_display_loop2
  mov r5,0
  pop {lr}
bx lr

tree_picture_display_loop2:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop6  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b tree_picture_display_loop2  @re entering loop
  exit_picture_display_loop6:
bx lr


tree_picture_3_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop7
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop7:
  cmp r6, 500  @number of repeats
  bge exit_loop7  @exit loop
  push {lr}
  bl displayTreeImage3 @does this
  pop {lr}
  b loop7
exit_loop7:
bx lr

displayTreeImage3:
  push {lr}
  mov r4,0 @rows
  ldr r5, =treePicture3 @address for dict
  bl tree_picture_display_loop3
  mov r5,0
  pop {lr}
bx lr

tree_picture_display_loop3:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop7  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b tree_picture_display_loop3  @re entering loop
  exit_picture_display_loop7:
bx lr


tree_picture_4_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop8
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop8:
  cmp r6, 500  @number of repeats
  bge exit_loop8  @exit loop
  push {lr}
  bl displayTreeImage4 @does this
  pop {lr}
  b loop8
exit_loop8:
bx lr

displayTreeImage4:
  push {lr}
  mov r4,0 @rows
  ldr r5, =treePicture4 @address for dict
  bl tree_picture_display_loop4
  mov r5,0
  pop {lr}
bx lr

tree_picture_display_loop4:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop8  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b tree_picture_display_loop4  @re entering loop
  exit_picture_display_loop8:
bx lr

tree_picture_5_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop9
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop9:
  cmp r6, 500  @number of repeats
  bge exit_loop9  @exit loop
  push {lr}
  bl displayTreeImage5 @does this
  pop {lr}
  b loop9
exit_loop9:
bx lr

displayTreeImage5:
  push {lr}
  mov r4,0 @rows
  ldr r5, =treePicture5 @address for dict
  bl tree_picture_display_loop5
  mov r5,0
  pop {lr}
bx lr

tree_picture_display_loop5:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop9  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b tree_picture_display_loop5  @re entering loop
  exit_picture_display_loop9:
bx lr


tree_picture_6_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop10
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop10:
  cmp r6, 500  @number of repeats
  bge exit_loop10  @exit loop
  push {lr}
  bl displayTreeImage6 @does this
  pop {lr}
  b loop10
exit_loop10:
bx lr

displayTreeImage6:
  push {lr}
  mov r4,0 @rows
  ldr r5, =treePicture6 @address for dict
  bl tree_picture_display_loop6
  mov r5,0
  pop {lr}
bx lr

tree_picture_display_loop6:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop10  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b tree_picture_display_loop6  @re entering loop
  exit_picture_display_loop10:
bx lr

food_picture_1_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop11
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop11:
  cmp r6, 500  @number of repeats
  bge exit_loop11  @exit loop
  push {lr}
  bl displayFoodImage1 @does this
  pop {lr}
  b loop11
exit_loop11:
bx lr

@-----------------------------------------------------------------------------------------

displayFoodImage1:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture1 @address for dict
  bl food_picture_display_loop1
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop1:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop11  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop1  @re entering loop
  exit_picture_display_loop11:
bx lr

food_picture_2_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop12
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop12:
  cmp r6, 500  @number of repeats
  bge exit_loop12  @exit loop
  push {lr}
  bl displayFoodImage2 @does this
  pop {lr}
  b loop12
exit_loop12:
bx lr

displayFoodImage2:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture2 @address for dict
  bl food_picture_display_loop2
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop2:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop12  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop2  @re entering loop
  exit_picture_display_loop12:
bx lr


food_picture_3_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop13
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop13:
  cmp r6, 500  @number of repeats
  bge exit_loop13  @exit loop
  push {lr}
  bl displayFoodImage3 @does this
  pop {lr}
  b loop13
exit_loop13:
bx lr

displayFoodImage3:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture3 @address for dict
  bl food_picture_display_loop3
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop3:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop13  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop3  @re entering loop
  exit_picture_display_loop13:
bx lr

food_picture_4_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop14
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop14:
  cmp r6, 500  @number of repeats
  bge exit_loop14  @exit loop
  push {lr}
  bl displayFoodImage4 @does this
  pop {lr}
  b loop14
exit_loop14:
bx lr

displayFoodImage4:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture4 @address for dict
  bl food_picture_display_loop4
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop4:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop14  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop4  @re entering loop
  exit_picture_display_loop14:
bx lr

food_picture_5_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop15
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop15:
  cmp r6, 500  @number of repeats
  bge exit_loop15  @exit loop
  push {lr}
  bl displayFoodImage5 @does this
  pop {lr}
  b loop15
exit_loop15:
bx lr

displayFoodImage5:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture5 @address for dict
  bl food_picture_display_loop5
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop5:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop15  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop5  @re entering loop
  exit_picture_display_loop15:
bx lr

food_picture_6_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop16
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop16:
  cmp r6, 500  @number of repeats
  bge exit_loop16  @exit loop
  push {lr}
  bl displayFoodImage6 @does this
  pop {lr}
  b loop16
exit_loop16:
bx lr

displayFoodImage6:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture6 @address for dict
  bl food_picture_display_loop6
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop6:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop16  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop6  @re entering loop
  exit_picture_display_loop16:
bx lr


food_picture_7_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop17
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop17:
  cmp r6, 500  @number of repeats
  bge exit_loop17  @exit loop
  push {lr}
  bl displayFoodImage7 @does this
  pop {lr}
  b loop17
exit_loop17:
bx lr

displayFoodImage7:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture7 @address for dict
  bl food_picture_display_loop7
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop7:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop17  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop7  @re entering loop
  exit_picture_display_loop17:
bx lr

food_picture_8_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop18
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop18:
  cmp r6, 500  @number of repeats
  bge exit_loop18  @exit loop
  push {lr}
  bl displayFoodImage8 @does this
  pop {lr}
  b loop18
exit_loop18:
bx lr

displayFoodImage8:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture8 @address for dict
  bl food_picture_display_loop8
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop8:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop18  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop8  @re entering loop
  exit_picture_display_loop18:
bx lr

food_picture_9_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop19
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop19:
  cmp r6, 500  @number of repeats
  bge exit_loop19  @exit loop
  push {lr}
  bl displayFoodImage9 @does this
  pop {lr}
  b loop19
exit_loop19:
bx lr

displayFoodImage9:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture9 @address for dict
  bl food_picture_display_loop9
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop9:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop19  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop9  @re entering loop
  exit_picture_display_loop19:
bx lr

food_picture_10_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop20
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop20:
  cmp r6, 500  @number of repeats
  bge exit_loop20  @exit loop
  push {lr}
  bl displayFoodImage10 @does this
  pop {lr}
  b loop20
exit_loop20:
bx lr

displayFoodImage10:
  push {lr}
  mov r4,0 @rows
  ldr r5, =foodPicture10 @address for dict
  bl food_picture_display_loop10
  mov r5,0
  pop {lr}
bx lr

food_picture_display_loop10:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop20  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b food_picture_display_loop10  @re entering loop
  exit_picture_display_loop20:
bx lr

headPat_picture_1_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop21
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop21:
  cmp r6, 500  @number of repeats
  bge exit_loop21  @exit loop
  push {lr}
  bl displayHeadImage1 @does this
  pop {lr}
  b loop21
exit_loop21:
bx lr

displayHeadImage1:
  push {lr}
  mov r4,0 @rows
  ldr r5, =headpat1 @address for dict
  bl headPat_loop1
  mov r5,0
  pop {lr}
bx lr

headPat_loop1:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop21  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b headPat_loop1  @re entering loop
  exit_picture_display_loop21:
bx lr

headPat_picture_2_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop22
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop22:
  cmp r6, 500  @number of repeats
  bge exit_loop22  @exit loop
  push {lr}
  bl displayHeadImage2 @does this
  pop {lr}
  b loop22
exit_loop22:
bx lr

displayHeadImage2:
  push {lr}
  mov r4,0 @rows
  ldr r5, =headpat2 @address for dict
  bl headPat_loop2
  mov r5,0
  pop {lr}
bx lr

headPat_loop2:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop22  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b headPat_loop2  @re entering loop
  exit_picture_display_loop22:
bx lr

headPat_picture_3_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop23
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop23:
  cmp r6, 500  @number of repeats
  bge exit_loop23  @exit loop
  push {lr}
  bl displayHeadImage3 @does this
  pop {lr}
  b loop23
exit_loop23:
bx lr

displayHeadImage3:
  push {lr}
  mov r4,0 @rows
  ldr r5, =headpat3 @address for dict
  bl headPat_loop3
  mov r5,0
  pop {lr}
bx lr

headPat_loop3:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop23  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b headPat_loop3  @re entering loop
  exit_picture_display_loop23:
bx lr

headPat_picture_4_second:
  push {lr}
  mov r4,0 @repeat number
  ldr r6, =0 @ageCounter for loop
  bl loop24
  mov r6,0
  mov r5,0
  pop {lr}
bx lr

loop24:
  cmp r6, 500  @number of repeats
  bge exit_loop24  @exit loop
  push {lr}
  bl displayHeadImage4 @does this
  pop {lr}
  b loop24
exit_loop24:
bx lr

displayHeadImage4:
  push {lr}
  mov r4,0 @rows
  ldr r5, =headpat4 @address for dict
  bl headPat_loop4
  mov r5,0
  pop {lr}
bx lr

headPat_loop4:
  cmp r4, 5  @check if row is 5, if true then exit loop
  bge exit_picture_display_loop24  @exit loop
  push {lr}
  bl displayPicture
  pop {lr}
  b headPat_loop4  @re entering loop
  exit_picture_display_loop24:
bx lr
@--------------------------------------------------------------------------------------------------------

input_timer:
  push {lr}



  pop {lr}
bx lr

big_timer:
  push {lr}
  ldr r9, =2000000
  bl delayE
  pop {lr}
bx lr

timer:
  push {lr}
  ldr r9, =5000
  bl delayE
  pop {lr}
bx lr

small_timer:
  push {lr}
  ldr r9, =400000
  bl delayE
  pop {lr}
bx lr

delayE:
  subs r9, r9, 1
  cmp r9, 0
  bne delayE
bx lr

@Code Below is for copy paste template 

@ loopStructure:
@   push {lr}
@   mov r4,0 @repeat number
  
@   b looop
@   mov r5,0
@   pop {lr}
@ bx lr

@ looop:
@   cmp r4, 5  @number of repeats
@   bge exit_picture_display_loop1e  @exit loop
@   push {lr}
@   bl displayPicture @does this
@   pop {lr}
@   b looop  @re entering loop
@   exit_picture_display_loop1e:
@ bx lr


.data
@maybe add a global states for press both buttons at once shit
actionState:
  .word 0 @excercise
  .word 0 @eating
  .word 0 @head pats

ageCounter:
  .word 150 @age count down
stats:
  .word 4 @ exercise start off with 4
  .word 5 @ health start off with 5
  .word 5 @happiness start of with 5 ig increased to 10 adds +10 to life duration
dogPicture:
.word 0b01101
.word 0b10100
.word 0b10000
.word 0b10001
.word 0b01110
dogPicture2:
.word 0b10101
.word 0b01100
.word 0b10000
.word 0b10001
.word 0b10101
deadDogPicture1:
.word 0b10001
.word 0b01010
.word 0b00000
.word 0b10001
.word 0b10001
deadDogPicture2:
.word 0b01010
.word 0b10101
.word 0b01010
.word 0b11111
.word 0b10001
treePicture:
.word 0b11000
.word 0b11000
.word 0b11000
.word 0b11101
.word 0b11101
treePicture2:
.word 0b11000
.word 0b11000
.word 0b11000
.word 0b11101
.word 0b01101
treePicture3:
.word 0b11000
.word 0b11000
.word 0b11000
.word 0b11101
.word 0b10101
treePicture4:
.word 0b11000
.word 0b11000
.word 0b11000
.word 0b11101
.word 0b11001
treePicture5:
.word 0b11000
.word 0b11000
.word 0b11000
.word 0b10101
.word 0b11101
treePicture6:
.word 0b11000
.word 0b11000
.word 0b11000
.word 0b11101
.word 0b01101
foodPicture1:
.word 0b11111
.word 0b01110
.word 0b10001
.word 0b01110
.word 0b11111
foodPicture2:
.word 0b01110
.word 0b10001
.word 0b01110
.word 0b11111
.word 0b11111
foodPicture3:
.word 0b10001
.word 0b01110
.word 0b11111
.word 0b11111
.word 0b11111
foodPicture4:
.word 0b01110
.word 0b11111
.word 0b11111
.word 0b11111
.word 0b11111
foodPicture5:
.word 0b10101
.word 0b11111
.word 0b10001
.word 0b10101
.word 0b10001
foodPicture6:
.word 0b10101
.word 0b11111
.word 0b10001
.word 0b10101
.word 0b00000
foodPicture7:
.word 0b10101
.word 0b11111
.word 0b10001
.word 0b00100
.word 0b10001
foodPicture8:
.word 0b10101
.word 0b11111
.word 0b00100
.word 0b10001
.word 0b00100
foodPicture9:
.word 0b10101
.word 0b11111
.word 0b11111
.word 0b00000
.word 0b11111
foodPicture10:
.word 0b10101
.word 0b11111
.word 0b01110
.word 0b10001
.word 0b11111
headpat1:
.word 0b00100
.word 0b01010
.word 0b10001
.word 0b10001
.word 0b11011
headpat2:
.word 0b00000
.word 0b00010
.word 0b00001
.word 0b00001
.word 0b10011
headpat3:
.word 0b00000
.word 0b00000
.word 0b00001
.word 0b00001
.word 0b11011
headpat4:
.word 0b00100
.word 0b01000
.word 0b10000
.word 0b10000
.word 0b11001

