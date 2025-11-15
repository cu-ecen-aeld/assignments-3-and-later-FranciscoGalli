CFLAGS = -Wall -Wextra -pedantic -g
TARGET = writer
SRC = writer.c
CC = $(CROSS_COMPILE)gcc


all: $(TARGET)

$(TARGET):$(SRC)
	echo "Executing $(CC) $(CFLAGS) -o $(TARGET) $(SRC)"
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)
	
	
clean: 
	echo  "Executing rm -f $(TARGET)"
	rm -f $(TARGET)
