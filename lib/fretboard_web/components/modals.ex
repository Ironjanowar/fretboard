defmodule FretboardWeb.Modals do
  @moduledoc """
  Modal dialog components for the fretboard visualizer.

  Provides the tuning, key, and chord progression modals
  as reusable function components.
  """

  use FretboardWeb, :html

  alias Fretboard.Music

  @doc """
  Returns the chord color at a given index, cycling through the color palette.
  """
  @spec chord_color(non_neg_integer(), [String.t()]) :: String.t()
  def chord_color(index, colors) do
    Enum.at(colors, rem(index, length(colors)))
  end

  # --- Tuning Modal ---

  attr :show, :boolean, required: true
  attr :modal_tuning_state, :map, required: true
  attr :instrument, :atom, required: true
  attr :string_count, :integer, required: true

  def tuning_modal(%{show: false} = assigns) do
    ~H"""
    """
  end

  def tuning_modal(assigns) do
    assigns =
      assign(
        assigns,
        :modal_preset,
        Music.detect_preset(assigns.instrument, assigns.modal_tuning_state.pitches)
      )

    assigns = assign(assigns, :modal_tuning, Music.tuning_notes(assigns.modal_tuning_state))

    ~H"""
    <%= if @show do %>
      <div
        id="tuning-modal"
        class="modal-overlay"
      >
        <div class="modal-backdrop" phx-click="close_tuning_modal"></div>
        <div class="modal-content">
          <div class="modal-handle"></div>
          <h2 class="modal-title">Tuning</h2>

          <%!-- Preset Dropdown --%>
          <form phx-change="select_preset" class="form-group">
            <label class="form-label">Preset</label>
            <select
              id={"preset-select-#{@modal_preset}"}
              class="form-select-full"
              name="preset"
            >
              <%= for name <- Music.instrument_preset_names(@instrument) do %>
                <option value={name} selected={@modal_preset == name}>{name}</option>
              <% end %>
              <option value="Custom" selected={@modal_preset == "Custom"}>Custom</option>
            </select>
          </form>

          <%!-- Individual String Dropdowns (String 6 to String 1, top to bottom) --%>
          <div
            class="form-group-spaced"
            id={"string-dropdowns-#{Enum.join(@modal_tuning, "")}"}
            phx-update="replace"
          >
            <%= for string_num <- @string_count..1//-1 do %>
              <% string_idx = @string_count - string_num %>
              <% current_note = Enum.at(@modal_tuning, string_idx) %>
              <form
                phx-change="change_string"
                class="string-row"
                id={"string-form-#{string_idx}"}
              >
                <label class="string-label">String {string_num}</label>
                <input type="hidden" name="string" value={string_idx} />
                <select
                  id={"string-select-#{string_idx}"}
                  class="form-select-full string-select"
                  name="note"
                >
                  <%= for note <- Music.chromatic_scale() do %>
                    <option value={note} selected={note == current_note}>
                      {note}
                    </option>
                  <% end %>
                </select>
              </form>
            <% end %>
          </div>

          <%!-- Buttons --%>
          <div class="modal-buttons">
            <button
              type="button"
              phx-click="close_tuning_modal"
              class="btn btn-ghost"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="apply_tuning"
              class="btn btn-primary"
            >
              Apply
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # --- Key Modal ---

  attr :show, :boolean, required: true
  attr :key_tonic, :string, required: true
  attr :key_scale_type, :atom, required: true
  attr :key_chord_mode, :atom, required: true
  attr :chord_colors, :list, required: true

  def key_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        id="key-modal"
        class="modal-overlay"
      >
        <div class="modal-backdrop" phx-click="close_key_modal"></div>
        <div class="modal-content">
          <div class="modal-handle"></div>
          <h2 class="modal-title">Key</h2>

          <form phx-change="update_key" id="key-form">
            <div class="form-row">
              <div class="form-col">
                <label class="form-label">Tonic</label>
                <select
                  id={"key-tonic-select-#{@key_tonic}"}
                  class="form-select-full"
                  name="key[tonic]"
                >
                  <%= for note <- Music.chromatic_scale() do %>
                    <option value={note} selected={@key_tonic == note}>{note}</option>
                  <% end %>
                </select>
              </div>
              <div class="form-col">
                <label class="form-label">Scale</label>
                <select
                  id={"key-scale-select-#{@key_scale_type}"}
                  class="form-select-full"
                  name="key[scale_type]"
                >
                  <%= for {group, scale_types} <- Music.grouped_scale_types() do %>
                    <optgroup label={group}>
                      <%= for st <- scale_types do %>
                        <option value={st} selected={@key_scale_type == st}>
                          {Music.scale_label(st)}
                        </option>
                      <% end %>
                    </optgroup>
                  <% end %>
                </select>
              </div>
              <div class="form-col">
                <label class="form-label">Chords</label>
                <select
                  id={"key-chord-mode-select-#{@key_chord_mode}"}
                  class="form-select-full"
                  name="key[chord_mode]"
                >
                  <option value="triad" selected={@key_chord_mode == :triad}>Triads</option>
                  <option value="seventh" selected={@key_chord_mode == :seventh}>7ths</option>
                </select>
              </div>
            </div>
          </form>

          <%!-- Preview Diatonic Chords --%>
          <div class="form-group-spaced">
            <label class="section-label">Diatonic Chords</label>
            <div
              class="key-preview-wrapper"
              id={"key-preview-#{@key_tonic}-#{@key_scale_type}-#{@key_chord_mode}"}
              phx-update="replace"
            >
              <%= for {chord, i} <- Enum.with_index(Music.diatonic_chords(@key_tonic, @key_scale_type, @key_chord_mode)) do %>
                <span
                  class="key-preview-chip"
                  style={"background-color: #{chord_color(i, @chord_colors)}"}
                >
                  {Music.chord_label(chord.root, chord.quality)}
                </span>
              <% end %>
            </div>
          </div>

          <%!-- Buttons --%>
          <div class="modal-buttons">
            <button
              type="button"
              phx-click="close_key_modal"
              class="btn btn-ghost"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="apply_key"
              class="btn btn-primary"
            >
              Apply
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # --- Progression Modal ---

  attr :show, :boolean, required: true
  attr :progression_id, :atom, required: true
  attr :progression_tonic, :string, required: true
  attr :chord_colors, :list, required: true

  def progression_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        id="progression-modal"
        class="modal-overlay"
      >
        <div class="modal-backdrop" phx-click="close_progression_modal"></div>
        <div class="modal-content">
          <div class="modal-handle"></div>
          <h2 class="modal-title">Chord Progressions</h2>

          <form phx-change="update_progression" id="progression-form">
            <div class="form-row">
              <div class="form-col">
                <label class="form-label">Progression</label>
                <select
                  id="progression-select"
                  class="form-select-full"
                  name="progression[id]"
                >
                  <%= for {category, progressions} <- Music.grouped_progressions() do %>
                    <optgroup label={category}>
                      <%= for prog <- progressions do %>
                        <option value={prog.id} selected={@progression_id == prog.id}>
                          {prog.name}
                        </option>
                      <% end %>
                    </optgroup>
                  <% end %>
                </select>
              </div>
              <div class="form-col">
                <label class="form-label">Tonic</label>
                <select
                  id="progression-tonic-select"
                  class="form-select-full"
                  name="progression[tonic]"
                >
                  <%= for note <- Music.chromatic_scale() do %>
                    <option value={note} selected={@progression_tonic == note}>{note}</option>
                  <% end %>
                </select>
              </div>
            </div>
          </form>

          <%!-- Preview Chords --%>
          <div class="form-group-spaced">
            <label class="section-label">Chords</label>
            <div
              class="key-preview-wrapper"
              id={"progression-preview-#{@progression_tonic}-#{@progression_id}"}
              phx-update="replace"
            >
              <%= for {chord, i} <- Enum.with_index(Music.progression_chords(@progression_tonic, @progression_id)) do %>
                <span
                  class="key-preview-chip"
                  style={"background-color: #{chord_color(i, @chord_colors)}"}
                >
                  {Music.chord_label(chord.root, chord.quality)}
                </span>
              <% end %>
            </div>
          </div>

          <%!-- Buttons --%>
          <div class="modal-buttons">
            <button
              type="button"
              phx-click="close_progression_modal"
              class="btn btn-ghost"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="apply_progression"
              class="btn btn-primary"
            >
              Apply
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
