from machine import lightsleep, Pin, PWM
from time import sleep

MAX_DUTY_CYCLE = 65_535
FORTY_PERCENT_DUTY_CYCLE = (MAX_DUTY_CYCLE * 2) // 5

# PWM fans use a frequency of 25 kHz.
PWM_FAN_FREQUENCY = 25_000

ONE_MILLISECOND = 0.001

# For PWM use GPIO pin #29, which is pin A0 on the Adafruit QT Py RP2040.
# PWM_PIN = 29

# For PWM use GPIO pin #15, which is pin #20 on the Raspberry Pi Pico.
PWM_PIN = 15

pwm0 = PWM(Pin(PWM_PIN))

pwm0.freq(PWM_FAN_FREQUENCY)

# Reduce the speed of the fan to 40% by setting the PWM duty cycle to 40%.
pwm0.duty_u16(FORTY_PERCENT_DUTY_CYCLE)

# Wait 15 seconds before initiating light sleep.
# This allows accessing the board for the first 15 seconds after it it receives power.
sleep(15)

while True:
    lightsleep(2)
    pwm0.freq(PWM_FAN_FREQUENCY)
    # Reduce the speed of the fan to 40% by setting the PWM duty cycle to 40%.
    pwm0.duty_u16(FORTY_PERCENT_DUTY_CYCLE)
    sleep(ONE_MILLISECOND)
