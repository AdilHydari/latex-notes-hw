CC      := gcc
CFLAGS  := -Wall -Wextra -pedantic -std=c11
TARGET  := option_b_signals
SRC     := optionB.c

.PHONY: all
all: part1 part3

.PHONY: part1
part1: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $@

.PHONY: part3
part3: $(TARGET)_p3

$(TARGET)_p3: $(SRC)
	$(CC) $(CFLAGS) -DPART3 $(SRC) -o $@

.PHONY: clean
clean:
	$(RM) $(TARGET) $(TARGET)_p3
