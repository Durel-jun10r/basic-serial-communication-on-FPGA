import serial
import time

PORT = "COM4"      # change to your FPGA COM port
BAUD = 9600

ser = serial.Serial(PORT, BAUD, timeout=1)

counter = 1

print("Starting number sender...")

try:
    while True:
        msg = f"{counter}\n"
        ser.write(msg.encode())
        print(f"Sent: {counter}")

        # read echo
        response = ser.readline().decode(errors='ignore').strip()
        if response:
            print(f"Echoed back: {response}")

        # increment and wrap
        counter += 1
        if counter > 10:
            counter = 1

        time.sleep(10)

except KeyboardInterrupt:
    print("Stopped.")
finally:
    ser.close()
