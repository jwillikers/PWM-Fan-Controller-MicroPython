from machine import Pin, PWM

# For PWM Use GPIO pin #29, which is pin A0 on the QT Py RP2040.
pwm0 = PWM(Pin(29))

# PWM fans use a frequency of 25 kHz.
pwm0.freq(25000)

# Reduce the speed of the fan to 40% by setting the PWM duty cycle to 40%.
# The duty cycle can be set to a number between 0 and 65,535.
# Thus, the required value is 65535 * 0.40 = 26,214.
pwm0.duty_u16(26214)
