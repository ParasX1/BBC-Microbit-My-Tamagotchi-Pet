# Tamagotchi Pet Game in ARMv7


## Overview

Welcome to the Tamagotchi Pet Game, a delightful and simple ARMv7 assembly project that brings the joy of raising a virtual pet to your BBC micro:bit! In this game, you'll be responsible for taking care of an adorable puppy by interacting with interrupts and making strategic decisions to keep it happy and healthy.

## Gameplay

- **Puppy Tail Wagging Animation:** The main pattern played on a loop is the puppy's tail wagging animation.
- **Button A (Walk at the Park):** Takes the dog on a walk, adding 2 points to Exercise, deducting a point from health/hunger, and aging the puppy.
- **Button B (Feed the Dog):** Feeds the dog a bone, adding 2 points to health/hunger and deducting a point from the age counter.
- **Button C (Pat the Dog):** Pats the dog, adding 2 points to happiness and deducting 1 point from happiness.

## Conditional Bonuses and Detriments

- **Conditional Bonuses:**
  1. Accumulating 10 points in Exercise adds 10 seconds to the overall 150 seconds of gameplay.
  2. Keeping the dog happy (10+ points) extends the dog's life via the age counter.

- **Conditional Detriments:**
  - If the age counter or hunger hits 0, or if hunger reaches 10, the dog dies.

## Code Structure

The code is designed with easily extendable functions that read images stored in memory. A loop is used to create fast images by incrementing a row and reading LED instructions from a `.data` spec. Nested loops repeat this process, allowing for approximately 1-second image displays. Labels call frames based on interrupts or no action, and small branches automatically deduct global values based on the context.

Labels for LED matrix pins simplify coding, debugging, and readability, providing an easier way to reference pinouts.

## Project Goals

The goal of this project was to create a fun and simple game where players can engage with their virtual pet for a few minutes. Testing has shown positive feedback, with players enjoying the challenge of keeping the puppy alive. While the game is intentionally kept simple, future improvements may focus on repeatability and extendability to make it more accessible to a wider audience.

## How to Use

1. Clone this repository to your local machine.
2. Connect your micro:bit to your computer.
3. Write the ARMv7 assembly code in the designated file.
4. Assemble and download the code to the micro:bit.
5. Enjoy playing and taking care of your virtual Tamagotchi pet!


## License

This project is licensed under the [MIT License](LICENSE).
