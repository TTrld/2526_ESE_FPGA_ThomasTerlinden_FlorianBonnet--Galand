//#include "system.h"
//#include "altera_avalon_pio_regs.h"
//#include "unistd.h"
//#include <stdio.h>
//
//
//int main(void) //chenillard
//{
//    unsigned int led = 1;  // 0b0000000001 → LED0
//
//    printf("Chenillard demarre\r\n");
//
//    while (1)
//    {
//        IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, led);
//        usleep(DELAY_US);
//
//        led <<= 1;  // décalage vers la LED suivante
//
//        if (led >= (1 << PIO_0_DATA_WIDTH))
//            led = 1; // retour à LED0
//    }
//
//    return 0;
//}


#include <stdio.h>
#include <stdint.h>
#include <unistd.h>    // pour usleep
#include <math.h>
#include "altera_avalon_i2c.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"


// Adresse I2C de l'ADXL345
#define ADXL345_ADDR    0x53

// Registres
#define DEVID_REG       0x00
#define POWER_CTL_REG   0x2D
#define DATA_X0_REG     0x32

// Constante de conversion LSB -> g pour ±2g
#define LSB_TO_G        0.004f


#define NUM_LEDS PIO_0_DATA_WIDTH


// Initialise l'ADXL345
int adxl345_init(ALT_AVALON_I2C_DEV_t *i2c_dev) {
    alt_u8 rx;
    alt_u8 tx = DEVID_REG;

    // Sélection de l'adresse de l'ADXL345
    alt_avalon_i2c_master_target_set(i2c_dev, ADXL345_ADDR);

    // Lire le registre DEVID
    if (alt_avalon_i2c_master_tx_rx(i2c_dev, &tx, 1, &rx, 1, ALT_AVALON_I2C_NO_INTERRUPTS) != 0) {
        printf("Erreur I2C lecture DEVID\n");
        return -1;
    }

    if (rx != 0xE5) {
        printf("ADXL345 non détecté (DEVID=0x%02X)\n", rx);
        return -1;
    }

    printf("ADXL345 détecté (DEVID=0x%02X)\n", rx);

    // Mettre l'accéléromètre en mode mesure (Measure = 1)
    alt_u8 txbuf[2] = {POWER_CTL_REG, 0x08};
    if (alt_avalon_i2c_master_tx(i2c_dev, txbuf, 2, ALT_AVALON_I2C_NO_INTERRUPTS) != 0) {
        printf("Erreur I2C écriture POWER_CTL\n");
        return -1;
    }

    return 0;
}

// Lire les axes X, Y, Z
void adxl345_read_axes(ALT_AVALON_I2C_DEV_t *i2c_dev, float *x_g, float *y_g, float *z_g) {
    alt_u8 tx = DATA_X0_REG;
    alt_u8 rx[6];

    alt_avalon_i2c_master_target_set(i2c_dev, ADXL345_ADDR);

    if (alt_avalon_i2c_master_tx_rx(i2c_dev, &tx, 1, rx, 6, ALT_AVALON_I2C_NO_INTERRUPTS) != 0) {
        printf("Erreur I2C lecture axes\n");
        *x_g = *y_g = *z_g = 0.0f;
        return;
    }

    int16_t x = (rx[1] << 8) | rx[0];
    int16_t y = (rx[3] << 8) | rx[2];
    int16_t z = (rx[5] << 8) | rx[4];

    *x_g = x * LSB_TO_G;
    *y_g = y * LSB_TO_G;
    *z_g = z * LSB_TO_G;
}

// Calcul de l'angle pour le niveau à bulles
float calculate_tilt(float x_g, float y_g) {
    return atan2f(y_g, x_g) * 180.0f / 3.14159265f;
}

//allumage leds
void update_bubble_leds(float y_g) {
    // On contraint y_g entre -1.0 et 1.0 pour éviter les débordements
    if (y_g > 1.0f) y_g = 1.0f;
    if (y_g < -1.0f) y_g = -1.0f;

    // Calcul de l'index :
    // On transforme [-1, 1] en [0, 1] -> (y_g + 1.0) / 2.0
    // Puis on multiplie par 9 pour avoir un index entre 0 et 9
    int led_index = (int)((y_g + 1.0f) / 2.0f * 9.0f);

    // Création du masque binaire (ex: si index=3, 1 << 3 = 0000001000)
    uint32_t led_mask = (1 << led_index);

    // Écriture sur le port PIO des LEDs
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, led_mask);
}

int main() {
    ALT_AVALON_I2C_DEV_t *i2c_dev = alt_avalon_i2c_open("/dev/i2c_0");
    if (!i2c_dev) {
        printf("Erreur: impossible d'ouvrir le périphérique I2C\n");
        return -1;
    }
    printf("OK\n");

    if (adxl345_init(i2c_dev) != 0) return -1;

//    while (1) {
//        float x, y, z;
//        adxl345_read_axes(i2c_dev, &x, &y, &z);
//
//        float angle = calculate_tilt(x, y);
//
//        printf("X=%.3fg Y=%.3fg Z=%.3fg Angle=%.1f°\n", x, y, z, angle);
//
//        usleep(200000); // pause 200 ms
//    }

    while (1) {
        float x, y, z;
        adxl345_read_axes(i2c_dev, &x, &y, &z);

        update_bubble_leds(y);

        float angle = atan2f(y, z) * 180.0f / 3.14159f;
        printf("Y=%.3fg | Angle=%.1f° | LED Index\n", y, angle);

        usleep(50000); // 50ms (20Hz)
    }

    return 0;
}

