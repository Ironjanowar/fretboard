# Fretboard Visualizer

A web app for visualizing chord notes across a guitar fretboard.

## Language

**Fretboard**:
The grid of strings × frets that represents the guitar neck. Each position on the fretboard produces a specific note.
_Avoid_: Neck, mástil (in code)

**String**:
One of the six horizontal wires on the fretboard, numbered 1–6 from thinnest (highest pitch) to thickest (lowest pitch). In the data model, string index 0 is the 6th string (low E) and index 5 is the 1st string (high E). In the horizontal fretboard view, string 1 (high E) is rendered at the top and string 6 (low E) at the bottom, matching the guitarist's perspective looking down at the instrument. Each string has a tuning note that determines the pitch of all its fret positions.
_Avoid_: Wire, cuerda (in code)

**Fret**:
A vertical position on the fretboard, numbered 0–24. Fret 0 is the open string (nut position). Each fret raises the pitch by one semitone from the previous fret.
_Avoid_: Position, slot

**Nut**:
The zero-fret position at the left edge of the fretboard where open strings sound. Visually distinct from regular frets.
_Avoid_: Capo, cejuela (in code)

**Note**:
One of the 12 chromatic pitch classes: C, C#, D, D#, E, F, F#, G, G#, A, A#, B. In v1, notes have no octave — they are pitch classes only.
_Avoid_: Tone, pitch (when referring to the label)

**Tuning**:
The set of 6 notes assigned to the open strings. Standard tuning is E A D G B E (from lowest to highest string).
_Avoid_: Configuration, setup

**Chord**:
A named combination of a root note and a chord quality. A chord defines which notes to highlight on the fretboard. Example: "C major" = root C + quality major.
_Avoid_: Voicing (that's a specific fingering, not the abstract chord)

**Root**:
The base note of a chord. The first note in the chord formula. Example: in "A minor", the root is A.
_Avoid_: Tonic (reserved for scales), base

**Quality**:
The type of a chord that determines its interval formula. Triads: major [0,4,7], minor [0,3,7], dim [0,3,6], aug [0,4,8], sus2 [0,2,7], sus4 [0,5,7]. Sevenths: 7 [0,4,7,10], maj7 [0,4,7,11], min7 [0,3,7,10], dim7 [0,3,6,9], m7b5 [0,3,6,10].
_Avoid_: Type, kind, mode

**Tuning Preset**:
A named, predefined tuning configuration (e.g., Standard, Drop D, DADGAD). Selecting a preset sets all six string notes at once. The user can then edit individual strings for a custom variation.
_Avoid_: Tuning template, tuning profile

**Chord Formula**:
A list of semitone intervals from the root that defines which notes belong to a chord quality. Example: major = [0, 4, 7] means root, major third, perfect fifth.
_Avoid_: Pattern, shape, intervals (when referring to the stored definition)

**Active Chord**:
A chord currently selected by the user for visualization on the fretboard. Multiple chords can be active simultaneously, each with an assigned color.
_Avoid_: Selected chord, enabled chord

**Overlap**:
When a note on the fretboard belongs to two or more active chords. Overlapping notes display in a neutral color with tooltip/click to reveal which chords they belong to.
_Avoid_: Collision, shared note, conflict

## Example dialogue

> **Dev:** The user picks "C major" and "A minor" — what lights up?
>
> **Domain expert:** Every fret position whose **note** matches any note in either **chord formula**. C major has C, E, G. A minor has A, C, E. So you'll see all C, E, G, and A positions. The C and E positions are **overlaps** — they show in the neutral color.
>
> **Dev:** What if the user changes the **tuning** of the low E string to D?
>
> **Domain expert:** Every **note** on that **string** shifts down by two semitones. The **active chords** don't change — the fretboard just recalculates which **fret** positions match.
