def main():
    used = set()
    last_reading = ""
    n = 0
    with open("../BPMFBase.txt") as f:
        lines = f.readlines()
        for line in lines:
            n += 1
            line = line.strip()
            components = line.split(" ")
            reading = components[1]
            if reading != last_reading:
                if reading in used:
                    print(f"Duplicate reading: {reading}")
                    print(f"#{n} {line}")
                else:
                    used.add(reading)
                last_reading = reading

if __name__ == "__main__":
    main()
