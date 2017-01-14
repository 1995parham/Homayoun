#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9
/* Create MFRC522 instance */
MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
	/* Initialize serial communications with the PC */
	Serial.begin(9600);	
	/* Initialize SPI bus */
	SPI.begin();
	/* Initialize MFRC522 instance */
	mfrc522.PCD_Init();
	Serial.println("Scan PICC to see UID and type...");
}

void loop() {
	/* Look for new cards */
	if (!mfrc522.PICC_IsNewCardPresent()) {
		return;
	}

	/* Select one of the cards */
	if (!mfrc522.PICC_ReadCardSerial()) {
		return;
	}

	/* Dump debug info about the card. PICC_HaltA() is automatically called. */
	mfrc522.PICC_DumpToSerial(&(mfrc522.uid));
}