from machine import Pin, PWM

MAX_DUTY_CYCLE = 65_535
FORTY_PERCENT_DUTY_CYCLE = (MAX_DUTY_CYCLE * 2) // 5

# PWM fans use a frequency of 25 kHz.
PWM_FAN_FREQUENCY = 25_000

# For PWM use GPIO pin #29, which is pin A0 on the Adafruit QT Py RP2040.
QT_PY_RP2040_PIN_A0 = 29

pwm0 = PWM(Pin(QT_PY_RP2040_PIN_A0))

pwm0.freq(PWM_FAN_FREQUENCY)

# Reduce the speed of the fan to 40% by setting the PWM duty cycle to 40%.
pwm0.duty_u16(FORTY_PERCENT_DUTY_CYCLE)
