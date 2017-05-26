defmodule HomeDetection.Application do
  use Application

  # RGB LCD Screen should use the IC2-1 port
  @sound_pin 0  # Port A0
  @led_pin 3  # Port D3

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(GrovePi.Sound, [@sound_pin]),
      worker(HomeDetection, [[@sound_pin, @led_pin]]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: HomeDetection.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
