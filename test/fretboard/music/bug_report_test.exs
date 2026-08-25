defmodule Fretboard.Music.BugReportTest do
  @moduledoc """
  Tests that expose bugs found during static analysis of the fretboard project.

  Each describe block targets a specific bug with a failing test that
  demonstrates the incorrect behavior.
  """
  use ExUnit.Case, async: true

  alias Fretboard.Music.{Chord, Note, Scale}

  # ─────────────────────────────────────────────────────────────────────
  # Bug A: @chord_member_rank assigns rank 0 to semitone 1 (Flat 9th),
  #        causing it to sort right after the Root instead of after the
  #        7th where extensions belong.
  #
  # In chord.ex line 205: `1 => 0` — the flat 9th is ranked as a root-level
  # chord member. The correct rank for a flat 9th extension is 4 (same as
  # the major 9th), since it functions as a 9th, not a root.
  #
  # This affects `interval_labels/1` for any chord containing semitone 1
  # with a 7th present (e.g. :"7b9", :"7b9b13", :"13b9").
  # ─────────────────────────────────────────────────────────────────────

  describe "Bug A: Flat 9th sorts in wrong position in interval_labels" do
    test "7b9 interval labels: Flat 9th should come after Minor 7th, not after Root" do
      labels = Chord.interval_labels(:"7b9")

      # Formula: [0, 1, 4, 7, 10] → Root, Flat 9th, Major 3rd, Perfect 5th, Minor 7th
      # Expected chord-member order: Root, Major 3rd, Perfect 5th, Minor 7th, Flat 9th
      assert labels == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Flat 9th"
             ]
    end

    test "7b9b13 interval labels: extensions sorted after chord tones" do
      labels = Chord.interval_labels(:"7b9b13")

      # Formula: [0, 1, 4, 7, 8, 10]
      # Expected: Root, Major 3rd, Perfect 5th, Minor 7th, Flat 9th, Minor 13th
      assert labels == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Flat 9th",
               "Minor 13th"
             ]
    end

    test "13b9 interval labels: Flat 9th after 7th, Major 13th last" do
      labels = Chord.interval_labels(:"13b9")

      # Formula: [0, 1, 4, 5, 7, 9, 10]
      # Expected: Root, Major 3rd, Perfect 5th, Minor 7th, Flat 9th, Perfect 11th, Major 13th
      assert labels == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Flat 9th",
               "Perfect 11th",
               "Major 13th"
             ]
    end
  end

  # ─────────────────────────────────────────────────────────────────────
  # Bug B: Note.note_index/1 returns nil for flat note names (Db, Eb, Gb,
  #        Ab, Bb) because the chromatic scale uses sharps only.
  #
  # The @flat_to_sharp normalization map exists in Scale.ex (line 378) but
  # Note.ex has no equivalent. This causes silent failures downstream:
  # identify/1 returns [] for valid chords in flat notation, and
  # note_at/2 crashes with ArithmeticError.
  # ─────────────────────────────────────────────────────────────────────

  describe "Bug B: Note module does not handle flat note names" do
    test "note_index returns correct index for Db (enharmonic C#)" do
      # Db is enharmonically equivalent to C#, which is index 1
      assert Note.note_index("Db") == 1
    end

    test "note_index returns correct index for Bb (enharmonic A#)" do
      assert Note.note_index("Bb") == 10
    end

    test "note_index returns correct index for Ab (enharmonic G#)" do
      assert Note.note_index("Ab") == 8
    end

    test "note_at does not crash on flat base note" do
      # This currently raises ArithmeticError: rem(nil + semitones, 12)
      assert Note.note_at("Db", 0) == "C#"
    end

    test "note_at calculates correctly from flat base note" do
      # Db + 7 semitones = Ab = G#
      assert Note.note_at("Db", 7) == "G#"
    end
  end

  # ─────────────────────────────────────────────────────────────────────
  # Bug C: Chord.identify/1 silently returns [] for valid chord notes
  #        provided in flat notation, because it relies on Note.note_index
  #        which returns nil for flats (see Bug B).
  #
  # A user playing Db major (Db-F-Ab) gets no chord identification.
  # ─────────────────────────────────────────────────────────────────────

  describe "Bug C: identify/1 fails on flat note names" do
    test "Db-F-Ab should identify as Db major (enharmonic C# major)" do
      results = Chord.identify(["Db", "F", "Ab"])

      # Should find the chord — Db major is a valid triad
      refute results == [],
             "identify/1 returned [] for Db-F-Ab, a valid major triad in flat notation"

      [first | _] = results
      # Db major is enharmonically C# major
      assert first.exact == true
    end

    test "Bb-D-F should identify as Bb major (enharmonic A# major)" do
      results = Chord.identify(["Bb", "D", "F"])

      refute results == [],
             "identify/1 returned [] for Bb-D-F, a valid major triad in flat notation"
    end
  end

  # ─────────────────────────────────────────────────────────────────────
  # Bug D: Scale.suggest_multi_keys/1 produces a spurious unmatched group
  #        when the input contains duplicate chords.
  #
  # In scale.ex, covered_chord_indices/2 uses Enum.find_index(chords, &(&1 == chord))
  # to map covered chord maps back to input indices. For duplicate chords,
  # find_index always returns the first occurrence, so subsequent duplicates
  # are never marked as covered and appear in the unmatched group.
  #
  # Example: [C major, C major, G major] — C major scale covers all 3,
  # but index 1 (second C major) is never in the covered set, producing
  # an extra %{key: nil, chords: [C major]} group.
  # ─────────────────────────────────────────────────────────────────────

  describe "Bug D: suggest_multi_keys with duplicate chords" do
    defp chord(root, quality), do: %{root: root, quality: quality}

    test "duplicate C major chords should all be covered, no unmatched group" do
      results =
        Scale.suggest_multi_keys([
          chord("C", :major),
          chord("C", :major),
          chord("G", :major)
        ])

      # C major scale covers C, C, and G — all 3 chords.
      # There should be NO unmatched group (key: nil).
      unmatched = Enum.filter(results, fn g -> g.key == nil end)

      assert unmatched == [],
             "Expected no unmatched group, but got: #{inspect(unmatched)}"
    end

    test "all C major duplicates covered when C major scale is selected" do
      results =
        Scale.suggest_multi_keys([
          chord("C", :major),
          chord("C", :major),
          chord("C", :major)
        ])

      # All 3 chords are C major, covered by C major scale.
      # No unmatched group should exist.
      unmatched = Enum.filter(results, fn g -> g.key == nil end)

      assert unmatched == [],
             "Expected no unmatched group for 3 identical C major chords, got: #{inspect(unmatched)}"
    end
  end

  # ─────────────────────────────────────────────────────────────────────
  # Bug E: Note.note_index/1 spec claims non_neg_integer() but returns
  #        nil for unknown notes. This is a spec violation that can cause
  #        silent failures in callers that don't check for nil.
  # ─────────────────────────────────────────────────────────────────────

  describe "Bug E: Note.note_index/1 returns nil for invalid notes" do
    test "note_index for unknown note returns nil (spec says non_neg_integer)" do
      # The @spec says non_neg_integer() but returns nil
      # This is either a spec issue or the function should raise
      result = Note.note_index("H")

      # Documenting current behavior: returns nil (spec violation)
      # A correct implementation would either:
      # 1. Return an error tuple, or
      # 2. Raise on invalid input, or
      # 3. Update the spec to say non_neg_integer() | nil
      assert result == nil
    end
  end
end
