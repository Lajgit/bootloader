#include "app_ws2812.h"
#include "app_board.h"
#include "tim.h"
#include "string.h"
// 预设颜色RGB表
RGB_t Color_table[] =
    {
        {255, 0, 0},        // 红色
        {0, 255, 0},        // 绿色
        {0, 0, 255},        // 蓝色
        {0, 255, 255},      // 天蓝色
        {0xFF, 0x40, 0x81}, // 粉色
        {128, 216, 0},      // 黄色
        {127, 106, 0},      // 橘色
        {255, 255, 255},    // 白色
        {0, 0, 0},          // 无颜色
        {213, 0, 249},      // 紫色
};
void Light_SetAllColor(RGB_t color, uint16_t *buffer)
{
    uint8_t i, j;
    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
    {
        static const uint8_t Count[2] = {36U, 49U};
        uint8_t strip, component, mask;
        uint8_t grb[3] = {color.G, color.R, color.B};
        for (strip = 0U; strip < 2U; strip++)
        {
            uint32_t channel = strip ? TIM_CHANNEL_2 : TIM_CHANNEL_1;
            uint16_t offset = 1U;
            uint16_t size = (uint16_t)(1U + Count[strip] * 24U + 256U);
            /* 中文注释：复用原缓冲，按GRB高位先发；尾部低电平320us锁存。 */
            memset(buffer, 0, size * sizeof(uint16_t));
            for (i = 0U; i < Count[strip]; i++)
                for (component = 0U; component < 3U; component++)
                    for (mask = 0x80U; mask != 0U; mask >>= 1U)
                        buffer[offset++] = (grb[component] & mask) ? 10U : 4U;
            __HAL_TIM_SET_COMPARE(&htim3, channel, 0U);
            HAL_TIM_PWM_Start(&htim3, channel);
            HAL_Delay(1U);
            HAL_TIM_PWM_Stop(&htim3, channel);
            if (HAL_TIM_PWM_Start_DMA(&htim3, channel, (uint32_t *)buffer, size) == HAL_OK)
            {
                /* 最长49颗约1.8ms；等3ms完成后再复用缓冲，不占用其他板型路径。 */
                HAL_Delay(3U);
                HAL_TIM_PWM_Stop_DMA(&htim3, channel);
            }
            __HAL_TIM_SET_COMPARE(&htim3, channel, 0U);
            HAL_TIM_PWM_Start(&htim3, channel);
        }
        return;
    }
    for (i = 0; i < Light_RGBbuffer_SIZE; i++)
    {
        for (j = 0; j < 8; j++)
        {
            if (color.G & 0x01 == 1)
                buffer[i * 24 + j] = code1;
            else
                buffer[i * 24 + j] = code0;
        }
        for (j = 8; j < 16; j++)
        {
            if (color.R & 0x01 == 1)
                buffer[i * 24 + j] = code1;
            else
                buffer[i * 24 + j] = code0;
        }
        for (j = 16; j < 24; j++)
        {
            if (color.B & 0x01 == 1)
                buffer[i * 24 + j] = code1;
            else
                buffer[i * 24 + j] = code0;
        }
    }
    /*
     * 中文注释：
     * 弹界原Bootloader同时驱动TIM3_CH1和CH2；
     * 蟠桃原Bootloader只驱动TIM3_CH2；
     * 扭蛋机沿用当前使用的弹界Bootloader灯效逻辑。
     */
    if (Boot_BoardGetId() == BOOT_BOARD_PANTAO)
    {
        HAL_TIM_PWM_Start_DMA(&htim3, TIM_CHANNEL_2, (uint32_t *)buffer, Light_CRRbuffer_SIZE);
    }
    else
    {
        HAL_TIM_PWM_Start_DMA(&htim3, TIM_CHANNEL_1, (uint32_t *)buffer, Light_CRRbuffer_SIZE);
        HAL_TIM_PWM_Start_DMA(&htim3, TIM_CHANNEL_2, (uint32_t *)buffer, Light_CRRbuffer_SIZE);
    }
}