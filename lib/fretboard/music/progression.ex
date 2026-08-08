defmodule Fretboard.Music.Progression do
  @moduledoc """
  Chord progression catalog for the Fretboard visualizer.

  Each progression is a map with:
  - `:id` — unique atom identifier
  - `:name` — display label (e.g., "Pop: I-V-vi-IV")
  - `:degrees` — list of degree specs, each `%{degree: integer, accidental: integer, quality: atom | nil}`
    - `degree` is 1-7 (scale degree number)
    - `accidental` is an integer in [-2, 2] — semitone offset from the diatonic root
      (-1 flattens, +1 sharpens, 0 is the diatonic note)
    - `quality` is `nil` (use diatonic quality) or an explicit quality atom
  - `:scale_type` — any scale type atom (e.g. `:major`, `:minor`, `:phrygian_dominant`, `:dorian`, `:lydian`, etc.)
  - `:genre` — musical genre/tradition
  - `:description` — brief explanation
  - `:example_key` — a key to use as example (e.g., "C")
  - `:notable_songs` — list of well-known songs using this progression

  ## Accidentals in minor keys

  In a minor key, scale degrees 3, 6, and 7 are already "flat" relative to the
  parallel major (they are built into the minor scale formula `[0, 2, 3, 5, 7, 8, 10]`).
  Those degrees therefore use `accidental: 0` — an extra `accidental: -1` would
  flatten them a second time (e.g. degree 7 in A minor is G; flattening again
  would give G♭, which is wrong). Use `accidental: -1` on degrees 3, 6, 7 only
  in `:major`-key progressions, where it denotes modal interchange (♭III, ♭VI, ♭VII).

  ## Accidentals in phrygian dominant

  The phrygian dominant scale (`[0, 1, 4, 5, 7, 8, 10]`) has a major 3rd and a
  minor 2nd built in. Degree 2 is already ♭II (1 semitone from the root), so it
  needs `accidental: 0` — an extra `accidental: -1` would flatten it again. Degree
  3 is a major 3rd (e.g. G♯ in E), so to reach the ♭III chord it needs
  `accidental: -1`. The tonic is major.
  """

  alias Fretboard.Music.{Note, Scale}

  # ─────────────────────────────────────────────────────────────────────────────
  # Progression definitions
  # ─────────────────────────────────────────────────────────────────────────────

  @progressions [
    # ═══════════════════════════════════════════════════════════════════════════
    # A) FAMOUS / CLASSIC PROGRESSIONS
    # ═══════════════════════════════════════════════════════════════════════════

    %{
      id: :pop_i_v_vi_iv,
      name: "Pop: I-V-vi-IV",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Pop, pop-punk, rock",
      description: "The 'Axis of Awesome' progression — used in countless pop hits",
      example_key: "C",
      notable_songs: [
        "Don't Stop Believin'",
        "Let It Be",
        "No Woman No Cry",
        "I'm Yours",
        "Despacito"
      ]
    },
    %{
      id: :classic_i_iv_v,
      name: "Classic: I-IV-V",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Rock, blues, country, folk",
      description: "The foundational three-chord rock/blues progression",
      example_key: "G",
      notable_songs: ["Wild Thing", "La Bamba", "Twist and Shout", "Rock Around the Clock"]
    },
    %{
      id: :blues_12_bar,
      name: "Blues: 12-Bar (I-IV-V)",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Blues, rock, jazz",
      description: "The quintessential 12-bar blues form",
      example_key: "A",
      notable_songs: ["Sweet Home Chicago", "Pride and Joy", "Johnny B. Goode", "Red House"]
    },
    %{
      id: :jazz_ii_v_i,
      name: "Jazz: ii-V-I",
      category: "Famous / Classic",
      degrees: [
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz",
      description: "The most important progression in jazz; appears in virtually every standard",
      example_key: "C",
      notable_songs: ["Autumn Leaves", "All The Things You Are", "Tune Up"]
    },
    %{
      id: :fifties_i_vi_iv_v,
      name: "50s: I-vi-IV-V",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Doo-wop, 1950s pop, early rock & roll",
      description: "The '50s progression' or 'doo-wop progression'",
      example_key: "C",
      notable_songs: ["Earth Angel", "Stand By Me", "Everyday", "Duke of Earl"]
    },
    %{
      id: :pachelbel_canon,
      name: "Classical: Pachelbel (I-V-vi-iii-IV-I-IV-V)",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 3, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Classical, baroque, pop",
      description: "Based on Pachelbel's Canon — descending fifth circular motion",
      example_key: "C",
      notable_songs: ["Canon in D", "Basket Case", "Graduation (Friends Forever)"]
    },
    %{
      id: :pop_vi_iv_i_v,
      name: "Pop: vi-IV-I-V",
      category: "Famous / Classic",
      degrees: [
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Pop, adult contemporary",
      description: "Same chords as I-V-vi-IV starting on vi — more melancholic, yearning quality",
      example_key: "C",
      notable_songs: ["Apologize", "Glycerine", "Save Tonight", "Zombie"]
    },
    %{
      id: :rock_i_bvii_iv,
      name: "Rock: I-bVII-IV",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: -1, quality: nil},
        %{degree: 4, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Rock, folk-rock (mixolydian)",
      description:
        "Uses the flattened 7th degree from mixolydian mode — quintessential rock sound",
      example_key: "D",
      notable_songs: ["Sweet Home Alabama", "A Hard Day's Night", "Sympathy for the Devil"]
    },
    %{
      id: :folk_i_iv,
      name: "Folk: I-IV",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Folk, rock, pop, drone",
      description: "Simplest common progression — creates an open, unresolved vamp",
      example_key: "E",
      notable_songs: ["Born in the U.S.A.", "Mellowship Slinky in B Major"]
    },
    %{
      id: :minor_pop_i_vi_iii_vii,
      name: "Pop: i-VI-III-VII",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 3, accidental: 0, quality: nil},
        %{degree: 7, accidental: 0, quality: nil}
      ],
      scale_type: :minor,
      genre: "Pop, EDM, dance",
      description: "Minor-key equivalent of vi-IV-I-V — extremely common in modern pop and EDM",
      example_key: "A",
      notable_songs: ["Wake Me Up", "Rolling in the Deep", "Don't You Worry Child", "Let Her Go"]
    },
    %{
      id: :minor_pop_i_bvi_biii_bvii,
      name: "Pop: i-bVI-bIII-bVII",
      category: "Famous / Classic",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 3, accidental: 0, quality: nil},
        %{degree: 7, accidental: 0, quality: nil}
      ],
      scale_type: :minor,
      genre: "Pop, rock",
      description:
        "All-natural-minor diatonic chords — the most common minor-key four-chord loop",
      example_key: "A",
      notable_songs: ["Mr. Brightside", "Disturbia", "Stronger"]
    },
    %{
      id: :canon_rock,
      name: "Rock: V-i-VI-IV (Canon Rock)",
      category: "Famous / Classic",
      degrees: [
        %{degree: 5, accidental: 0, quality: :major},
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil}
      ],
      scale_type: :minor,
      genre: "Rock, instrumental guitar (harmonic minor)",
      description: "Fusion of Pachelbel's Canon with rock — uses harmonic minor raised 7th",
      example_key: "A",
      notable_songs: ["Canon Rock", "various Yngwie Malmsteen passages"]
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # B) CURIOUS / INTERESTING PROGRESSIONS
    # ═══════════════════════════════════════════════════════════════════════════

    %{
      id: :modal_interchange_i_iv,
      name: "Modal Interchange: I-iv",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: :minor}
      ],
      scale_type: :major,
      genre: "Pop, rock, classical",
      description: "Borrowing iv from parallel minor — creates emotional, bittersweet color",
      example_key: "C",
      notable_songs: ["Creep", "In My Life", "Beethoven Sonata Op. 13"]
    },
    %{
      id: :creep_progression,
      name: "Modal Interchange: I-III-IV-iv (Creep)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 3, accidental: 0, quality: :major},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: :minor}
      ],
      scale_type: :major,
      genre: "Alternative rock, art rock",
      description:
        "Chromatic mediant I→III plus modal interchange IV→iv — iconic Radiohead sound",
      example_key: "G",
      notable_songs: ["Creep", "SexyBack", "Loser"]
    },
    %{
      id: :chromatic_mediant_i_biii,
      name: "Chromatic Mediant: I-bIII",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 3, accidental: -1, quality: :major}
      ],
      scale_type: :major,
      genre: "Rock, film music, progressive",
      description: "Roots a major third apart — creates a dramatic, cinematic quality",
      example_key: "C",
      notable_songs: ["Where the Streets Have No Name", "Strawberry Fields Forever"]
    },
    %{
      id: :chromatic_mediant_i_bvi,
      name: "Chromatic Mediant: I-bVI",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 6, accidental: -1, quality: :major}
      ],
      scale_type: :major,
      genre: "Rock, film music, classical",
      description:
        "bVI borrowed from parallel minor — creates a broad, heroic, expansive quality",
      example_key: "C",
      notable_songs: ["Yesterday", "Dream On", "various film scores"]
    },
    %{
      id: :chromatic_mediant_i_iii,
      name: "Chromatic Mediant: I-III",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 3, accidental: 0, quality: :major}
      ],
      scale_type: :major,
      genre: "Jazz, classical, Broadway",
      description: "Roots a major third apart, both major — bright, unexpected harmonic lift",
      example_key: "C",
      notable_songs: ["Have You Met Miss Jones?"]
    },
    %{
      id: :neapolitan_i_bii_v_i,
      name: "Classical: Neapolitan (i-bII-V-i)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: -1, quality: :major},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :minor,
      genre: "Classical, jazz",
      description:
        "The Neapolitan chord (bII major) — dramatic pre-dominant function; related to tritone substitution",
      example_key: "A",
      notable_songs: ["Beethoven Piano Sonatas", "Schubert songs"]
    },
    %{
      id: :descending_chromatic_bass,
      name: "Chromatic: Descending Bass (I-i7-IV-iv6-I)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: :min7},
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: :min7},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Pop, jazz, classical",
      description:
        "Chromatic descending bass line — sophisticated and emotive; common in jazz ballads",
      example_key: "C",
      notable_songs: ["Stairway to Heaven", "My Funny Valentine", "Chelsea Bridge"]
    },
    %{
      id: :line_cliche_i_bvii_bvi_v,
      name: "Chromatic: Line Cliche (i-bVII-bVI-V)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: :major}
      ],
      scale_type: :minor,
      genre: "Jazz, pop, film",
      description:
        "Chromatic descending bass — the 'James Bond' chord progression; cinematic and mysterious",
      example_key: "A",
      notable_songs: ["My Favorite Things", "Europa", "various James Bond themes"]
    },
    %{
      id: :omnipotent_progression,
      name: "Classical: Omnipotent (I-VII-iv-iv°-III-II-I)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: -1, quality: :major},
        %{degree: 4, accidental: 0, quality: :minor},
        %{degree: 4, accidental: 0, quality: :dim},
        %{degree: 3, accidental: 0, quality: :major},
        %{degree: 2, accidental: 0, quality: :major},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Classical, Baroque",
      description:
        "Baroque descending bass line with passing diminished chord — foundational in classical music",
      example_key: "C",
      notable_songs: ["Bach chorales", "Stairway to Heaven (partial descent)"]
    },
    %{
      id: :ascending_bass_i_ii_iii_iv,
      name: "Pop: Ascending (I-ii-iii-IV)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: 0, quality: nil},
        %{degree: 3, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Pop, jazz",
      description:
        "Ascending stepwise motion through diatonic chords — gentle, building, optimistic",
      example_key: "C",
      notable_songs: ["Lean on Me (partial)", "various jazz ballad intros"]
    },
    %{
      id: :chromatic_walkdown_i_bvii_vi_bvii_i,
      name: "Rock: Chromatic Walkdown (I-bVII-VI-bVII-I)",
      category: "Curious / Interesting",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: -1, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 7, accidental: -1, quality: nil},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Rock, pop",
      description:
        "Stepwise descent from I to bVI with return through bVII — dramatic harmonic gesture",
      example_key: "A",
      notable_songs: ["Hey Jude (outro section)", "various rock ballads"]
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # C) EXOTIC / WORLD PROGRESSIONS
    # ═══════════════════════════════════════════════════════════════════════════

    %{
      id: :andalusian_cadence,
      name: "Flamenco: Andalusian Cadence (i-bVII-bVI-V)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: 0, quality: nil},
        %{degree: 6, accidental: 0, quality: nil},
        %{degree: 5, accidental: 0, quality: :major}
      ],
      scale_type: :minor,
      genre: "Flamenco, Spanish, classical, rock",
      description:
        "The most famous flamenco progression — descending bass from i to V; the raised 7th provides Spanish tension",
      example_key: "A",
      notable_songs: [
        "Hit the Road Jack",
        "California Dreamin'",
        "Stray Cat Strut",
        "Sultans of Swing",
        "Runaway"
      ]
    },
    %{
      id: :flamenco_phrygian_dominant,
      name: "Flamenco: Phrygian Dominant (I-bII-bIII-bII)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: 0, quality: :major},
        %{degree: 3, accidental: -1, quality: :major},
        %{degree: 2, accidental: 0, quality: :major}
      ],
      scale_type: :phrygian_dominant,
      genre: "Flamenco, Middle Eastern",
      description:
        "Phrygian dominant scale (5th mode of harmonic minor) — the tonic is major and the bII creates the characteristic flamenco bite",
      example_key: "E",
      notable_songs: ["various flamenco palos", "Middle Eastern-influenced rock/metal"]
    },
    %{
      id: :harmonic_minor_i_iv_v,
      name: "Harmonic Minor: i-iv-V",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: :minor},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :minor,
      genre: "Classical, Eastern European, metal",
      description:
        "Uses raised 7th (V instead of bVII) from harmonic minor for stronger dominant-tonal resolution",
      example_key: "A",
      notable_songs: ["various classical pieces", "klezmer", "neo-classical metal"]
    },
    %{
      id: :byzantine_double_harmonic,
      name: "Exotic: Byzantine / Double Harmonic (I-bII-I)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: -1, quality: :major},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Byzantine, Greek, Middle Eastern, Indian",
      description:
        "Based on the double harmonic scale with augmented 2nd intervals — the I-bII is the signature sound",
      example_key: "D",
      notable_songs: ["Miserlou", "Greek and Middle Eastern traditional music", "Bollywood"]
    },
    %{
      id: :hungarian_minor,
      name: "Exotic: Hungarian Minor (i-bII-iv)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: -1, quality: :major},
        %{degree: 4, accidental: 0, quality: :minor}
      ],
      scale_type: :minor,
      genre: "Hungarian, Eastern European, klezmer, gypsy jazz",
      description:
        "Hungarian minor scale (harmonic minor with raised 4th) — distinctive Eastern European / gypsy flavor",
      example_key: "A",
      notable_songs: [
        "Traditional Hungarian and Roma music",
        "Brahms Hungarian Dances",
        "Django Reinhardt gypsy jazz"
      ]
    },
    %{
      id: :japanese_hirajoshi,
      name: "World: Japanese / Hirajoshi (I-bII-V-bVI)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: -1, quality: nil},
        %{degree: 5, accidental: 0, quality: nil},
        %{degree: 6, accidental: -1, quality: nil}
      ],
      scale_type: :major,
      genre: "Japanese traditional, ambient, world fusion",
      description:
        "Based on hirajoshi pentatonic scale — distinctly Japanese harmonic colors; bII and bVI give Asian-influenced sound",
      example_key: "C",
      notable_songs: [
        "Traditional Japanese koto/shamisen music",
        "Joe Hisaishi (partial influence)"
      ]
    },
    %{
      id: :middle_eastern_hijaz,
      name: "World: Hijaz / Makam (I-bII-bIII-iv)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: 0, quality: :major},
        %{degree: 3, accidental: -1, quality: :major},
        %{degree: 4, accidental: 0, quality: :minor}
      ],
      scale_type: :phrygian_dominant,
      genre: "Middle Eastern, Arabic, Turkish makam",
      description:
        "The Hijaz mode/makam (phrygian dominant) — the tonic is major and the augmented 2nd between bII and bIII is the hallmark of Middle Eastern music",
      example_key: "D",
      notable_songs: [
        "Traditional Arabic/Turkish music",
        "Misirlou",
        "various Middle Eastern pop"
      ]
    },
    %{
      id: :klezmer_freygish,
      name: "World: Klezmer / Freygish (I-bII-III-VII)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: 0, quality: :major},
        %{degree: 3, accidental: -1, quality: :major},
        %{degree: 7, accidental: 0, quality: :major}
      ],
      scale_type: :phrygian_dominant,
      genre: "Klezmer, Jewish, Eastern European",
      description:
        "'Freygish' = Yiddish for phrygian dominant — the tonic is major and the I-bII-III movement is the core of klezmer harmony",
      example_key: "D",
      notable_songs: [
        "Hava Nagila (partial)",
        "Bei Mir Bist Du Schön",
        "various Eastern European folk"
      ]
    },
    %{
      id: :dorian_vamp_i_iv,
      name: "Modal: Dorian Vamp (i-IV)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: :min7},
        %{degree: 4, accidental: 0, quality: :"7"}
      ],
      scale_type: :minor,
      genre: "Jazz, rock, folk, funk (dorian mode)",
      description:
        "The raised 6th in dorian gives a brighter quality than natural minor — common in modal jazz",
      example_key: "D",
      notable_songs: ["So What", "Oye Como Va", "Eleanor Rigby", "Scarborough Fair"]
    },
    %{
      id: :dorian_aeolian_i_bvii_iv,
      name: "Modal: Dorian-Aeolian (i-bVII-IV)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: 0, quality: nil},
        %{degree: 4, accidental: 0, quality: nil}
      ],
      scale_type: :minor,
      genre: "Rock, funk, soul",
      description:
        "Combines dorian brightness with aeolian — the IV chord is the key dorian characteristic",
      example_key: "A",
      notable_songs: ["Roxanne", "Billie Jean (partial)", "Thriller (partial)"]
    },
    %{
      id: :lydian_i_ii,
      name: "Modal: Lydian (I-II)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: 0, quality: :major}
      ],
      scale_type: :major,
      genre: "Jazz, film, progressive rock (lydian mode)",
      description:
        "The II chord (major, not diminished) comes from the lydian raised 4th — floating, ethereal, dreamlike",
      example_key: "C",
      notable_songs: ["Dreams", "Flying in a Blue Dream", "various film scores"]
    },
    %{
      id: :whole_tone,
      name: "Modal: Whole Tone (I-II-III)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: :aug},
        %{degree: 2, accidental: 0, quality: :aug},
        %{degree: 3, accidental: 0, quality: :aug}
      ],
      scale_type: :major,
      genre: "Jazz, impressionist, film",
      description:
        "Based on the whole tone scale — augmented chords create a floating, ambiguous, otherworldly quality",
      example_key: "C",
      notable_songs: [
        "Debussy impressionist pieces",
        "Bemsha Swing (partial)",
        "various film dream sequences"
      ]
    },
    %{
      id: :mixolydian_bvi_i_bvii_bvi_bvii,
      name: "Modal: Mixolydian bVI (I-bVII-bVI-bVII)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 7, accidental: -1, quality: nil},
        %{degree: 6, accidental: -1, quality: nil},
        %{degree: 7, accidental: -1, quality: nil}
      ],
      scale_type: :major,
      genre: "Rock, pop (mixolydian with modal interchange)",
      description:
        "Combines mixolydian bVII with modal interchange bVI — rock anthem quality with dramatic lift",
      example_key: "C",
      notable_songs: ["Hey Jude (partial)", "various rock anthems"]
    },
    %{
      id: :phrygian_vamp_i_bii_i,
      name: "Modal: Phrygian (i-bII-i)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: -1, quality: :major},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :minor,
      genre: "Flamenco, metal, progressive rock (phrygian mode)",
      description:
        "The simplest phrygian vamp — the bII major chord creates the characteristic dark, tense phrygian sound",
      example_key: "E",
      notable_songs: ["Between the Wheels", "various metal and prog rock", "traditional flamenco"]
    },
    %{
      id: :spanish_phrygian_i_bii_iii,
      name: "Modal: Spanish Phrygian (i-bII-III)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: nil},
        %{degree: 2, accidental: -1, quality: :major},
        %{degree: 3, accidental: 0, quality: :major}
      ],
      scale_type: :minor,
      genre: "Flamenco, Spanish",
      description: "Adds the III chord to the phrygian vamp — common in Spanish guitar music",
      example_key: "A",
      notable_songs: ["various flamenco forms", "Malagueña"]
    },
    %{
      id: :blues_dominant_i7_iv7_v7,
      name: "Blues: Dominant 7th (I7-IV7-V7)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: :"7"},
        %{degree: 4, accidental: 0, quality: :"7"},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Blues, rock",
      description:
        "All dominant 7th chords — the defining blues characteristic (dominant 7th on I doesn't fit diatonic major)",
      example_key: "A",
      notable_songs: ["Pride and Joy", "Red House", "Sweet Home Chicago"]
    },
    %{
      id: :minor_blues_i7_iv7_v7,
      name: "Blues: Minor Blues (i7-iv7-V7)",
      category: "Exotic / World",
      degrees: [
        %{degree: 1, accidental: 0, quality: :min7},
        %{degree: 4, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :minor,
      genre: "Blues, jazz",
      description:
        "Minor-key blues — the V7 uses the harmonic minor raised 7th for stronger resolution",
      example_key: "A",
      notable_songs: ["The Thrill is Gone", "As The Years Go Passing By"]
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # D) JAZZ / SOPHISTICATED PROGRESSIONS
    # ═══════════════════════════════════════════════════════════════════════════

    %{
      id: :rhythm_changes_a,
      name: "Jazz: Rhythm Changes A (I-vi-ii-V)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :"7"},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Jazz, bebop",
      description:
        "The A section of rhythm changes — one of the two most important progressions in jazz (with blues)",
      example_key: "Bb",
      notable_songs: [
        "I Got Rhythm",
        "Oleo",
        "Anthropology",
        "The Flintstones Theme",
        "Rhythm-a-Ning"
      ]
    },
    %{
      id: :rhythm_changes_b,
      name: "Jazz: Rhythm Changes B (III7-VI7-II7-V7)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 3, accidental: 0, quality: :"7"},
        %{degree: 6, accidental: 0, quality: :"7"},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Jazz, bebop",
      description:
        "The B section (bridge) of rhythm changes — circle of fifths through secondary dominants",
      example_key: "Bb",
      notable_songs: ["I Got Rhythm bridge", "Oleo bridge", "Anthropology bridge"]
    },
    %{
      id: :coltrane_changes,
      name: "Jazz: Coltrane Changes (Giant Steps)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 5, accidental: -1, quality: :"7"},
        %{degree: 3, accidental: 1, quality: :maj7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz, post-bop",
      description:
        "Root movement by major thirds — three key centers an augmented triad apart; Coltrane's harmonic innovation",
      example_key: "Bb",
      notable_songs: ["Giant Steps", "Countdown", "Lazy Bird", "Satellite"]
    },
    %{
      id: :coltrane_sub_ii_v_i,
      name: "Jazz: Coltrane Sub (ii-V-I with major third substitution)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz",
      description:
        "Inserts a ii-V-I a major third away before resolving — creates rapid harmonic motion through distant keys",
      example_key: "C",
      notable_songs: ["Countdown", "Tune Up reharmonization"]
    },
    %{
      id: :backdoor_progression,
      name: "Jazz: Backdoor (iv-bVII7-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 4, accidental: 0, quality: :min7},
        %{degree: 7, accidental: -1, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz, soul",
      description:
        "Resolves to I via the 'back door' using iv and its dominant bVII7 — very common in modern jazz",
      example_key: "C",
      notable_songs: ["Lady Bird", "various jazz standards"]
    },
    %{
      id: :jazz_turnaround,
      name: "Jazz: Turnaround (I-vi-ii-V)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Jazz, pop",
      description:
        "The standard jazz turnaround — leads back to the top of the form; supports many substitutions",
      example_key: "C",
      notable_songs: ["end of nearly every jazz standard", "Rhythm Changes A section"]
    },
    %{
      id: :minor_ii_v_i,
      name: "Jazz: Minor ii-V-i",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 2, accidental: 0, quality: :m7b5},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :min7}
      ],
      scale_type: :minor,
      genre: "Jazz",
      description:
        "The minor key version of ii-V-I — ii is half-diminished (m7b5), V7 uses harmonic minor raised 7th",
      example_key: "A",
      notable_songs: ["Autumn Leaves (sections)", "Black Orpheus", "Blue Bossa (sections)"]
    },
    %{
      id: :tritone_sub_ii_bii_i,
      name: "Jazz: Tritone Substitution (ii-bII7-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 2, accidental: -1, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz",
      description:
        "Replaces V7 with bII7 — shares the same tritone, creating a chromatic bass descent; essential jazz substitution",
      example_key: "C",
      notable_songs: ["Misty", "Round Midnight", "most bebop standards"]
    },
    %{
      id: :secondary_dominant,
      name: "Jazz: Secondary Dominant (I-V/ii-ii-V-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 5, accidental: 1, quality: :"7"},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz, Broadway",
      description:
        "Uses a secondary dominant (V/ii) to approach ii chromatically — creates forward harmonic motion",
      example_key: "C",
      notable_songs: ["I've Got Rhythm", "various Broadway tunes"]
    },
    %{
      id: :bird_blues,
      name: "Jazz: Bird Blues",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :"7"},
        %{degree: 4, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Jazz, bebop",
      description:
        "Charlie Parker's reharmonization of the 12-bar blues with ii-V chains and substitutions",
      example_key: "Bb",
      notable_songs: ["Blues for Alice", "An Oscar for Oscar"]
    },
    %{
      id: :modal_jazz_vamp,
      name: "Jazz: Modal Vamp (i-iv)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :min7},
        %{degree: 4, accidental: 0, quality: :"7"}
      ],
      scale_type: :minor,
      genre: "Modal jazz (dorian)",
      description:
        "Modal jazz uses very few chords — often just a vamp, allowing extended improvisation on a single mode",
      example_key: "D",
      notable_songs: ["So What", "Impressions", "Maiden Voyage"]
    },
    %{
      id: :extended_ii_v_chain,
      name: "Jazz: Extended Chain (iii-vi-ii-V-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 3, accidental: 0, quality: :min7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz",
      description:
        "Extended circle-of-fifths chain — each chord resolves down a fifth to the next; smooth continuous motion",
      example_key: "C",
      notable_songs: ["many jazz standards, especially intros and turnarounds"]
    },
    %{
      id: :iv_minor_substitution,
      name: "Jazz: IV-iv-I (Minor Subdominant)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 4, accidental: 0, quality: :maj7},
        %{degree: 4, accidental: 0, quality: :min7},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Jazz, pop, soul",
      description:
        "The IV to iv movement — one of the most expressive modal interchange devices; also called 'minor plagal cadence'",
      example_key: "C",
      notable_songs: ["Night and Day", "Charleston", "many jazz standards"]
    },
    %{
      id: :plagal_cadence,
      name: "Classical: Plagal (IV-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 4, accidental: 0, quality: nil},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Classical, hymns, rock",
      description: "The 'Amen' cadence — less final than V-I but with a warm, resolved quality",
      example_key: "C",
      notable_songs: ["Amen cadence in hymns", "Hey Jude (ending)", "many rock endings"]
    },
    %{
      id: :deceptive_cadence,
      name: "Classical: Deceptive (V-vi)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 6, accidental: 0, quality: :minor}
      ],
      scale_type: :major,
      genre: "Classical, pop, jazz",
      description:
        "The V resolves deceptively to vi instead of I — creates surprise and extends the phrase",
      example_key: "C",
      notable_songs: [
        "Beethoven symphonies",
        "various classical pieces",
        "pop songs for unexpected resolution"
      ]
    },
    %{
      id: :minor_plagal,
      name: "Classical: Minor Plagal (iv-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 4, accidental: 0, quality: :minor},
        %{degree: 1, accidental: 0, quality: nil}
      ],
      scale_type: :major,
      genre: "Pop, jazz, soul",
      description:
        "The minor subdominant resolving to major tonic — bittersweet, nostalgic quality; very expressive modal interchange",
      example_key: "C",
      notable_songs: ["Creep (ending)", "various soul and R&B songs", "Beatles songs"]
    },
    %{
      id: :jazz_blues_form,
      name: "Jazz: Jazz Blues",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 1, accidental: 0, quality: :"7"},
        %{degree: 4, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :"7"},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Jazz, blues",
      description: "The jazz blues adds ii-V chains and turnarounds to the basic blues form",
      example_key: "Bb",
      notable_songs: ["Tenor Madness", "Blue Monk", "Freddie Freeloader", "Straight, No Chaser"]
    },
    %{
      id: :bossa_nova_ii_v_i,
      name: "Jazz: Bossa Nova (ii-V-I)",
      category: "Jazz / Sophisticated",
      degrees: [
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7}
      ],
      scale_type: :major,
      genre: "Bossa nova, Brazilian jazz",
      description:
        "Brazilian jazz typically uses ii-V-I with extended chord voicings (9ths, 11ths, 13ths)",
      example_key: "C",
      notable_songs: ["The Girl from Ipanema", "Desafinado", "Blue Bossa", "Corcovado"]
    },
    %{
      id: :aaba_form,
      name: "Jazz: AABA Form",
      category: "Jazz / Sophisticated",
      degrees: [
        # A
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        # B (bridge)
        %{degree: 3, accidental: 0, quality: :"7"},
        %{degree: 6, accidental: 0, quality: :"7"},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"},
        # A
        %{degree: 1, accidental: 0, quality: :maj7},
        %{degree: 6, accidental: 0, quality: :min7},
        %{degree: 2, accidental: 0, quality: :min7},
        %{degree: 5, accidental: 0, quality: :"7"}
      ],
      scale_type: :major,
      genre: "Jazz, Broadway, Tin Pan Alley",
      description:
        "The most important song form in jazz besides blues — 32 bars in AABA structure",
      example_key: "C",
      notable_songs: ["I Got Rhythm", "Blue Moon", "Satin Doll", "A Foggy Day"]
    }
  ]

  # ─────────────────────────────────────────────────────────────────────────────
  # Public API
  # ─────────────────────────────────────────────────────────────────────────────

  @progression_categories [
    "Famous / Classic",
    "Curious / Interesting",
    "Exotic / World",
    "Jazz / Sophisticated"
  ]

  @doc """
  Returns all progressions as a list of maps.
  """
  @spec all() :: [map()]
  def all, do: @progressions

  @doc """
  Returns the list of progression ids (atoms).
  """
  @spec available_progressions() :: [atom()]
  def available_progressions, do: Enum.map(@progressions, & &1.id)

  @doc """
  Returns the list of progression category names in display order.
  """
  @spec categories() :: [String.t()]
  def categories, do: @progression_categories

  @doc """
  Returns progressions organized in groups by category for UI display.
  Returns a list of `{category_name, progressions}` tuples.
  """
  @spec grouped_progressions() :: [{String.t(), [map()]}]
  def grouped_progressions do
    Enum.map(@progression_categories, fn category ->
      {category, Enum.filter(@progressions, &(&1.category == category))}
    end)
  end

  @doc """
  Returns the progression with the given id, or `nil` if not found.
  """
  @spec progression(atom()) :: map() | nil
  def progression(id), do: Enum.find(@progressions, &(&1.id == id))

  @doc """
  Returns the display label (the `:name` field) for the given progression id,
  or `nil` if the progression is not found.
  """
  @spec progression_label(atom()) :: String.t() | nil
  def progression_label(id) do
    case progression(id) do
      nil -> nil
      prog -> prog.name
    end
  end

  @doc """
  Resolves a progression to a list of chord maps for the given tonic.

  Each chord is `%{root: String.t(), quality: atom()}`. For each degree spec:

  - The diatonic chord at that degree is looked up via `Scale.diatonic_chords/2`.
  - If `accidental` is non-zero, the root is shifted by that many semitones.
  - Quality is chosen as: the explicit `quality` if given, the diatonic quality
    if `accidental == 0`, or an inferred quality for common altered degrees
    (♭II/♭III/♭VI/♭VII become `:major`).

  ## Examples

      iex> Fretboard.Music.Progression.progression_chords("C", :pop_i_v_vi_iv)
      [%{root: "C", quality: :major}, %{root: "G", quality: :major},
       %{root: "A", quality: :minor}, %{root: "F", quality: :major}]
  """
  @spec progression_chords(String.t(), atom()) :: [%{root: String.t(), quality: atom()}]
  def progression_chords(tonic, progression_id) do
    prog = progression(progression_id)
    diatonic = Scale.diatonic_chords(tonic, prog.scale_type)

    Enum.map(prog.degrees, &resolve_degree_chord(&1, Enum.at(diatonic, &1.degree - 1)))
  end

  defp resolve_degree_chord(%{degree: deg, accidental: acc, quality: qual}, diatonic_chord) do
    root = degree_root(diatonic_chord.root, acc)
    quality = degree_quality(deg, acc, qual, diatonic_chord.quality)
    %{root: root, quality: quality}
  end

  defp degree_root(diatonic_root, 0), do: diatonic_root

  defp degree_root(diatonic_root, accidental) do
    Note.note_at(diatonic_root, accidental)
  end

  defp degree_quality(_degree, _accidental, explicit_quality, _diatonic_quality)
       when not is_nil(explicit_quality) do
    explicit_quality
  end

  defp degree_quality(_degree, 0, nil, diatonic_quality), do: diatonic_quality

  defp degree_quality(degree, accidental, nil, diatonic_quality) do
    infer_altered_quality(degree, accidental, diatonic_quality)
  end

  # Altered degrees flattened by one semitone in major-flavoured contexts
  # (♭II Neapolitan, ♭III, ♭VI, ♭VII) are conventionally major triads.
  defp infer_altered_quality(deg, acc, _diatonic_quality)
       when acc == -1 and deg in [2, 3, 6, 7],
       do: :major

  defp infer_altered_quality(_deg, _acc, diatonic_quality), do: diatonic_quality
end
