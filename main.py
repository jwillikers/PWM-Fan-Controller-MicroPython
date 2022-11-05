from machine import Pin, PWM

MAX_DUTY_CYCLE = 65_535
FORTY_PERCENT_DUTY_CYCLE = (MAX_DUTY_CYCLE * 2) // 5

# PWM fans use a frequency of 25 kHz.
PWM_FAN_FREQUENCY = 25_000

# For PWM use GPIO pin #29, which is pin A0 on the Adafruit QT Py RP2040.
# PWM_PIN = 29

# For PWM use GPIO pin #15, which is pin #20 on the Raspberry Pi Pico.
PWM_PIN = 15

pwm0 = PWM(Pin(PWM_PIN))

pwm0.freq(PWM_FAN_FREQUENCY)

# Reduce the speed of the fan to 40% by setting the PWM duty cycle to 40%.
pwm0.duty_u16(FORTY_PERCENT_DUTY_CYCLE)
