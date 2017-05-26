defmodule HomeDetection do
  @moduledoc false
  use GenServer
  require Logger

  alias GrovePi.{RGBLCD, Sound, Digital}

  defstruct [:sound, :led, :last_alert, :ref]

  def start_link(pins) do
    GenServer.start_link(__MODULE__, pins)
  end

  def init([sound_pin, led_pin]) do
    state = %HomeDetection{sound: sound_pin, led: led_pin}
    send(self(), :initialize)

    {:ok, state}
  end

  def handle_info(:initialize, state) do
    initialize_led(state.led)
    reset_monitor(state.led)

    Sound.subscribe(state.sound, :loud)
    Sound.subscribe(state.sound, :quiet)

    Logger.info "Home Detection initialized"

    {:noreply, state}
  end

  def handle_info({_pin, :loud, %{value: value}}, %{ref: nil} = state) do
    Logger.info "Received sound alert: value #{inspect value}"
    sound_alert(state.led)
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
    reset_monitor(state.led)

    {:noreply, %{state | ref: nil}}
  end

  def handle_info(:reset_monitor, %{last_alert: :loud} = state) do
    ref = schedule_monitor_reset()

    {:noreply, %{state | ref: ref}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp initialize_led(led) do
    Digital.set_pin_mode(led, :output)
    Digital.write(led, 1)
    :timer.sleep(1_000)
    Digital.write(led, 0)
  end

  defp sound_alert(led) do
    RGBLCD.set_rgb(255, 8, 0)
    RGBLCD.set_text("Noise Alert!")
    Digital.write(led, 1)
  end

  defp reset_monitor(led) do
    RGBLCD.set_rgb(0, 128, 64)
    RGBLCD.set_text("Monitoring...")
    Digital.write(led, 0)
  end

  def schedule_monitor_reset() do
    Process.send_after(self(), :reset_monitor, 5_000)
  end
end
