/*
** ONE-MUSEUM LESSON LOADER
**
** This is a low-level process for the updating of all of the information needed for a lesson
** as will be called from the OneMuseumIngestor when getting a Lesson to load
*/


USE OneMuseum;

SELECT GUID INTO @MuseumGUID FROM Museums WHERE Name = 'Museum of Mathematics';
SELECT GUID INTO @SubjectGUID FROM curriculumsubjects WHERE Name = 'Mathematics';
SELECT GUID INTO @ElementGUID FROM curriculumelements WHERE Code = 'M324';
SELECT GUID INTO @LessonTypeGUID FROM lessontypes WHERE Name = 'Lesson';

SET @Code = '';
SET @Name = 'Equations';

SET @Description = 'An outline of the nature of equations with examples';
SELECT @Keywords = 'equation, equality, RHS, LHS, right-hand side, left-hand side';


INSERT INTO Lessons (MuseumID, LessonTypeID, LessonType, CurriculumSubjectID, CurriculumElementID,
	Code, Name, Description, Keywords)
VALUES (@MuseumGUID, @LessonTypeGUID, @LessonType, @SubjectGUID, @ElementGUID,
	@Code, @Name, @Description, @Keywords);
    
SET @ID = LAST_INSERT_ID();
SELECT GUID INTO @LessonGUID
FROM Lessons
WHERE ID = @ID;

SELECT CONCAT('LESSON ID = ', @LessonGUID);

SELECT GUID INTO @ELementID FROM CUrriculumElements WHERE Code = 'M324';

INSERT INTO Categorizations (RefETID, RefGUID, CategoryETID, CategoryValueID, CategoryValue)
VALUES (565, @LessonGUID, 155, @ElementGUID, 'equation');

-- LESSON ID = D90DCDDB-FD39-5CF7-7F4B-9C256D1DF5BA

UPDATE Lessons SET Content = '# equations

## Scope

This lesson outlines the basics of equations in mathematics. This is a fundamental element of mathematical knowledge, and the manipulation of equations occurs throughout mathematics at all levels.

## Learning Objectives

* Understand the concept of equations and their role in mathematics
* Understand and apply the laws of equations
* Manipulate equations for various purposes
  * Change the subject of an equation
  * Solve linear equations
  * Combine like terms
* Reduce the errors made by learners in maniulating equations
* Analyse equations and break them down into parts
* Evaluate alternative approaches to solving equations
* Recall the history of the notation used to represent equations and equality between expressions

## Pre-Requisite Knowledge

* Basic arithmetic operations
* Mental arithmetic
* Expressions and terms
* Commutative, associative, and distribute laws in expresions

## Definition

An equation in mathematics is a statement that two mathematical expressions are equal.

The notion of equality between two expressions is fundamental to all of
mathematics, and equality is mostly determined in terms of the
value
of the expressions and not their form.

## LHS and RHS

An equation is written as follows in the language of mathematics:

```math
LHS = RHS
```

Where $`LHS`$ = left-hand side, and
$`RHS`$ = right-hand side.

>An equation can represent equality between more than two expressions, but these cases are unusual at the school level, and these can be broken down into the basic equation form as indicated above.

## Equations with numbers alone

For example, when considering numbers alone, it should be obvious that a number is equal to itself.

```math
8 = 8
```

> Can then we assume then that $`7=7`$ and $`5=5`$?
> In fact, can we conclude that no matter what the number $`n`$
that it is always true that $`n=n`$ - every number is always equal to itself.

## The equals sign $`=`$

The equals sign was first suggested by Robert Browne in 1557, in his work *"The Whetstone of Witte"*, for which an article was written in 1957 to celebrate the 400 year anniversay of this work [^1]. This was the start of the usage of this notation, and this because commonly used by the community of mathematics around one century later - it takes new notations a long time to gain acceptance in the mathematical world!

We are now already 450 years into the usage of the symbol $`=`$ to represent equality and equations.

## Equations with calculations

This extends to situations in which the value must be calculated, such as

```math
8 = 5 + 3
```

Since $`5 + 3`$ is equal to $`8`$ it is clear that both sides are the same value, even though their form is different.

## Equations with unknowns

In the early grades, when learning basic arithmetic operations, a problem to find a value is often given in the following form:

```math
2 + \\square = 7
```

The learner is required to provide the missing value.

This is the first type of exercise in which learners encounter unknown values,
but these unknown values do not have names at this point in mathematics education.

## Introducing symbols for unknown quantities

When algebra is first introduced to learners, these $`\\square`$ places in the equations are replaced by letters,
and by far the most common letter use is $`x`$.

So why is the letter $`x$` associated with the unknown?
This original usage in algebra has found its ways into many other areas in which it has been necessary
to express something unknown, such as x-rays, ...

```math
2 + x = 7
```

## The law of equations

The law of equations is that the equality between the LHS and the RHS is preserved when the same operation is conducted on both sides.

These operations are:

* addition of the same value to each side
* subtraction of the same value from each side
* multiply each side by the same value
* divide each side by the same value, so long as this value is not zero
* negate each side, which is the same as multiplying by $`-1`$
* squaring each size, or raising it to any power
* taking the square root, or any other root
* swap the $`LHS`$ and the $`RHS`$
* add another equation by adding the $`RHS`$ od the second equation
to the $`RHS`$ the first, and to add the $`LHS`$ of the second equation to the $`LHS`$ of the first equation

Eeach one of these operations ensures that the equality of the $`RHS`$ and the $`LHS`$ is preserved.

## Using the law of equations to manipulate equations

Given any equation, and with the need to reach a particular goal,
such as the solution of the equation, the challenge is which operations will achieve this goal.

The $`LHS`$ and $`RHS`$ can also be manulated in various ways without changing their meaning or value,
using the commutative, associative, and distributive properties of alegebraic expressions.

## Solving simple linear equations

This lesson is not concerned with the solution of equations, but since this is one of the major reasons
why you will be manipulating equations we will explore the simplest case,
being the solution of linear equations with a single variable.

A "solution" is the number (or numbers) which when replacing the variable will cause the equation to be true.
All other values will cause a problem.

Consider the following equation:

```math
x + 3 = 8
```

For this example, we have the expression $`x+3`$ on the LHS, with only the $`8`$ on the RHS of the equation.

Let us replace $`x`$ with the value $`2`$, which will result in the following equation:

```math
2+3 = 8
```

which is clearly incorrect, since $`2+3=5`$ and $`5 \\neq 8`$.

So the question we need to answer is "what value of $`x`$ will ensure that the equiation is true where the $`LHS=RHS`$".

When approaching a solution we are aiming for an equation which has the following form:

```math
x = N
```

where $`N`$ is a single number and is the solution to the equation.

To reach this solution we must carry out operations in accordance with the law of equations,
that the same operations are conducted on the $`LHS`$ and the $`RHS`$.

Looking at the $`LHS`$ we see that the expression $`x+3`$ must be transformed to just $`x`$,
and for this we need to find a way to remove the $`+3`$. However, we cannot just remove items in an equation
when we want to, but must always observe strict rules which preserve the qequality.

This problem should be simple for you - we subtract $`3`$ from the $`LHS`$ expression,
and then, in accordance with the law of equations we must also subtract $`3`$ from the $`RHS`$ 
to ensure that we preserve the equality between the two sides of the equation.

The first step in our solution is:

```math
x+3-3 = 8 - 3
```

On the LHS:  the $`+3-3`$ becomes $`0`$, and $`x+0`$ is the same as just $`x`$,
since adding $`0`$ any expression leaves this expression unchanged.

On the RHS: $`8-3 = 5`$.

Consequently, the solution, by subtracting $`3`$ from both sides, is:

```math
x = 5
```

which is in the form required for the solution.

## Exercises

Try the following yourself:

1. $`x - 5 = 21`$
2. $`2x + 12 = 24`$
3. $`12 = 3x`$
4. $`x - 5 = 2x + 15`$
5. $`5y = 20`$

Reflect on each of these problems:

* did you select the correct operations?
* is your answer correct? (you can test this by substituting the variable with your answer in the equation and check that the two sides are equal).
* did you apply the same operation to both sides?
* did you find any ways to shortcut the solution, perhaps doing two operations at the same time?
* The last exercise involves the variable $y$ and not $x$. How is this different to the others?

## Activities

Build some examples similar to the above exercises and solve these yourself.
Share these examples with each other and learn from each other.

Discuss any problems which you experience with creating examples,
and any issues you have with the examples presented by others.

Increase the complexity of your examples using division and fractions as well as addition, subtraction, and multiplication.

## References

[^1] Sanford, V. *Robert Recorde\'s "Whetsone of witte"*. The Mathematics Teacher, April 1957, Vol. 50, No. 4, pp. 258-266. <https://www.jstor.org/stable/27955396>
'
WHERE GUID = 'D90DCDDB-FD39-5CF7-7F4B-9C256D1DF5BA';


/*
---

<audio id="music" preload="auto" loop="false">
  <source src="1-11 Blackbird.mp3" type="audio/mp3">
</audio>

---

<video width="320" height="240" controls>
  <source src="movie.mp4" type="video/mp4">
  <source src="movie.ogg" type="video/ogg">
Your browser does not support the video tag.
</video>

---

*/
