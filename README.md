# HomeDetection

This example polls a sound sensor and sends a noise alert to a RGB LCD display 
and turns on an LED when a loud noise is heard.  The system returns to 
monitoring after 5 seconds.

On the GrovePi+ or GrovePi Zero, connect a LED to port D3, a sound sensor to 
port A0, and a RGB LCD display to the IC2-1 port.

This project was created as a Nerves app. To start your Nerves app:
  * `export NERVES_TARGET=my_target` or prefix every command with `NERVES_TARGET=my_target`, Example: `NERVES_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`
