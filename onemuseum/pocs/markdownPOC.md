
# Markdown Proof of Concept and Learning Exemplar

This is an example of what can be **done** with Markdown to
create web pages as simplified alternative to HTML

Each of the parts of this is incuded in its HTML form, immediately followed by its original MD form, for example see the following second-level heading...

## This is a level 2 heading

`## This is a level 2 heading`

---

## LINES: A line can be drawn using three - or * on the same line, such as

`---`
`* * *`

## HEADINGS: Each heading is a line starting with # ## ### for each level of heading

# Heading Level 1

    # Heading Level 1`

## Heading Level 2

    ## Heading Level 2`

### Heading Level 3

    ### Heading Level 3

#### Heading Level 4

    #### Heading Level 4

##### Heading Level 5

    ##### Heading Level 5

###### Heading Level 6

    ###### Heading Level 6

---

## CODE BLOCKS: Placing text into code blocks which disable HTML processing and show them as is

`Prefix with backquote

### Fenced Code Blocks for multi-line

> struggling to get this working, even using the fenced code block extension

    ```python
    import os, sys
    import markdown
    ```

---

## LISTS

* item 1
* item 2
* item 3

---

## UNORDERED LIST

* item 1
* item 2
* item 3

---

## BLOCKQUOTES

This is a normal line

> this is a blockquote
> this is another line
> and a third line

And then back to normal

---

## NUMBERED LISTS

1. APples
2. Oranges
3. Pears
4. Berries

---

## CODE BLOCKS

THis is normal text

    this is a code block
    and this is a second line

And back to normal

---

## LINKS

For the links there must be no space between the ] and the ()

This is [an example](http://www.onemuseum.net "Title") and this is more text.

---

## EMPHASIS

A way of producing *italic* text.

A way of _italic_ text

A way of **bolding** txt

A way of __alternate bold using underscore__

---

## IMAGES

![Alternative text](../static/img/belinda-fewings-_CyyAj0QboY-unsplash (Custom).jpg)
