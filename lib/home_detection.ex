defmodule HomeDetection do
  @moduledoc false
  use GenServer
  require Logger

  alias GrovePi.{RGBLCD, Sound, Digital}

  defstruct [:sound, :sound_led, :last_alert, :ref]

  def start_link(pins) do
    GenServer.start_link(__MODULE__, pins)
  end

  def init([sound_pin, sound_led_pin]) do
    state = %HomeDetection{sound: sound_pin, sound_led: sound_led_pin}
    send(self(), :initialize)

    {:ok, state}
  end

  def handle_info(:initialize, state) do
    Digital.set_pin_mode(state.sound_led, :output)
    Digital.write(state.sound_led, 1)
    :timer.sleep(1_000)
    Digital.write(state.sound_led, 0)

    reset_monitor(state.sound_led)

    Sound.subscribe(state.sound, :loud)
    Sound.subscribe(state.sound, :quiet)

    Logger.info "Home Detection initialized"

    {:noreply, state}
  end

  def handle_info({_pin, :loud, %{value: value}}, %{ref: nil} = state) do
    Logger.info "Received sound alert: value #{inspect value}"
    sound_alert(state.sound_led)
    ref = schedule_monitor_reset()

    {:noreply, %{state | last_alert: :loud, ref: ref}}
  end

  def handle_info({_pin, :loud, %{value: value}}, %{ref: ref} = state) do
    Logger.info "Received sound alert: value #{inspect value}"
    Process.cancel_timer(ref)
    ref = schedule_monitor_reset()

    {:noreply, %{state | last_alert: :loud, ref: ref}}
  end

  def handle_info({_pin, :quiet, %{value: value}}, state) do
    Logger.info "Back to quiet: value #{inspect value}"

    {:noreply, %{state | last_alert: :quiet}}
  end

  def handle_info(:reset_monitor, %{last_alert: :quiet} = state) do
    Logger.info "Back to monitoring..."
    reset_monitor(state.sound_led)

    {:noreply, %{state | ref: nil}}
  end

  def handle_info(:reset_monitor, %{last_alert: :loud} = state) do
    ref = schedule_monitor_reset()

    {:noreply, %{state | ref: ref}}
  end

  def handle_info(message, state) do
    Logger.info "Received unexpected message: #{inspect message}"

    {:noreply, state}
  end

  defp sound_alert(sound_led) do
    RGBLCD.set_text("Noise Alert!")
    Digital.write(sound_led, 1)
  end

  defp reset_monitor(sound_led) do
    RGBLCD.set_text("Monitoring...")
    Digital.write(sound_led, 0)
  end

  def schedule_monitor_reset() do
    Process.send_after(self(), :reset_monitor, 5_000)
  end
end
