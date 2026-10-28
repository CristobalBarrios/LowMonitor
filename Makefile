ASM = nasm
LD = ld
ASMFLAGS = -f elf64 -g -F dwarf
LDFLAGS = -m elf_x86_64

SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
TARGET = $(BIN_DIR)/lowmonitor

SRCS = $(SRC_DIR)/main.asm \
       $(SRC_DIR)/utils.asm \
       $(SRC_DIR)/mod1_cpu.asm \
       $(SRC_DIR)/mod2_ports.asm \
       $(SRC_DIR)/mod3_mem.asm \
       $(SRC_DIR)/mod4_perf.asm

all: directories $(TARGET)

directories:
	@mkdir -p $(BUILD_DIR) $(BIN_DIR)

$(BUILD_DIR)/main.o: $(SRCS)
	$(ASM) $(ASMFLAGS) $(SRC_DIR)/main.asm -o $(BUILD_DIR)/main.o

$(TARGET): $(BUILD_DIR)/main.o
	$(LD) $(LDFLAGS) $(BUILD_DIR)/main.o -o $(TARGET)

run-cli: all
	./$(TARGET) --all

clean:
	rm -rf $(BUILD_DIR)/*.o $(TARGET)
