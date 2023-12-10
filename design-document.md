
<!-- 
My tamagotchi "Puppy" is a fun small 3 min game in where the player tries to keep the fast aging puppy alive by interacting with interupts. It consists of 4 abilities.The main pattern played on a loop is the puppy tail wagging animation. The other 3 are Interrupts functions.
 
Button A: Takes the dog on a walk at the park, this affects stored global values. It adds 2 points to Exercise,deducts a point from health/hunger and age counter.
 
Button B: Feeds the dog a bone, this also affects stored global values by adding 2 points to health/hunger and deducts a point from the age counter.

Button C: Pats the dog, adds 2 points to happiness, - 1 for happiness.
 
Conditional Bonuses:
1.When the dog has accumulated 10 points in the Exercise value, it adds 10 to the overall 150 seconds of gameplay.
2.When the dog is happy (10+ points) it also extends the dog's life, via age counter. (For easy gameplay)
 
Conditional Detriments:
If the agecounter hits 0,or if hunger hits 0, or 10 the dog dies.
 
My code was created by implementing easily extendable functions (barely any copy paste needed)  which read images stored in memory. Using a loop which loops 5 times incrementing a row and reading a new line of led instructions from .data spec and creates a fast image. After this I created a nested loop which repeats the previous loop 300- 500 times which allows for an approx 1 second image on the screen. This was repeated for all image frames that I wanted to use for my tamagotchi, after which a label which calls all frames in order based on which interrupt or if no action is performed. I also created small branches which were called within these large frame labels, which automatically deducted the necessary global values based on function (the context mentioned above). After each interrupt, it was cleared and reset inorder for repeat useability.
 
I also created labels for the pins corresponding to the image of the LED matrix, which made it easier to code, debug, and read. This meant that instead of constantly having to remember or lookup the pinout, turning code that looked like this: `mov r0, 1 mov r1, 1 mov r2, 1 bl write_Led`
to code that instead looked like: `bl dog_picture_1_second`, which could be called repeatedly.
 
 
The goal of my  assignment was to create a fun yet simple game which a player can play for a few mins. This was achieved as many peers have played for at least 2 mins and enjoyed it, the feeling of "oh no keep the puppy alive" and similar thoughts proved my intentions at least a little, but testing also showed that it was still too short of a game to some. With more time, and possibly a more general design spec I could add a game which can be played.
 
It was appropriate and dare I say good use of memory, as animations and loops require lots of repeated code, I shortened these large functions list by using nested loops, which improved code quality. I chose this design as the goal was a Tamagotchi, it's intentionally kept super simple, and yet both entertaining to watch and play. It's not too complex but still offers nice strategic gameplay. However, an aspect of which I would like to improve in the future is more repeatability, as good understanding of ARM is needed to extend the game, however a smarter nested loop and use of systick timer would be better (I was sick during that lab).
 -->
