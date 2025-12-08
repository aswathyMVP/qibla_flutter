package com.example.qibla_ar_finder

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.util.AttributeSet
import android.view.View
import kotlin.math.abs

class AROverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {
    
    private var currentHeading = 0f
    private var qiblaBearing = 0f
    private var devicePitch = 0f
    
    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 48f
        isAntiAlias = true
        setShadowLayer(10f, 0f, 0f, Color.BLACK)
    }
    
    private val smallTextPaint = Paint().apply {
        color = Color.WHITE
        textSize = 32f
        isAntiAlias = true
        setShadowLayer(5f, 0f, 0f, Color.BLACK)
    }
    
    private val arrowPaint = Paint().apply {
        color = Color.GREEN
        strokeWidth = 8f
        isAntiAlias = true
        setShadowLayer(10f, 0f, 0f, Color.BLACK)
    }
    
    private val circlePaint = Paint().apply {
        color = Color.GREEN
        style = Paint.Style.STROKE
        strokeWidth = 4f
        isAntiAlias = true
    }
    
    fun updateHeading(heading: Float, qibla: Float, pitch: Float) {
        currentHeading = heading
        qiblaBearing = qibla
        devicePitch = pitch
        invalidate()
    }
    
    fun updateQiblaBearing(qibla: Float) {
        qiblaBearing = qibla
        invalidate()
    }
    
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        val width = width.toFloat()
        val height = height.toFloat()
        val centerX = width / 2
        val centerY = height / 2
        
        // Calculate angle difference
        var angleDiff = qiblaBearing - currentHeading
        
        // Normalize angle to -180 to 180
        while (angleDiff > 180) {
            angleDiff -= 360
        }
        while (angleDiff < -180) {
            angleDiff += 360
        }
        
        // Calculate Kaaba position on screen
        val fovHorizontal = 70f // Field of view in degrees
        val pixelsPerDegree = width / fovHorizontal
        val kaabaX = centerX + (angleDiff * pixelsPerDegree)
        val kaabaY = centerY - (devicePitch * (height / 50f) * 0.3f)
        
        // Draw Kaaba if on screen
        if (kaabaX > -100 && kaabaX < width + 100 && kaabaY > -100 && kaabaY < height + 100) {
            drawKaaba(canvas, kaabaX, kaabaY)
        }
        
        // Draw direction message
        if (abs(angleDiff) > 5) {
            val message = if (angleDiff < 0) "Move Left" else "Move Right"
            drawDirectionMessage(canvas, message, centerX, centerY)
        }
        
        // Draw compass info
        drawCompassInfo(canvas, centerX, centerY, width, height)
    }
    
    private fun drawKaaba(canvas: Canvas, x: Float, y: Float) {
        // Draw arrow pointing down
        canvas.drawLine(x, y - 40, x, y - 10, arrowPaint)
        canvas.drawLine(x - 15, y - 20, x, y - 10, arrowPaint)
        canvas.drawLine(x + 15, y - 20, x, y - 10, arrowPaint)
        
        // Draw Kaaba symbol (square)
        val size = 40f
        canvas.drawRect(x - size / 2, y, x + size / 2, y + size, circlePaint)
        
        // Draw circle around Kaaba
        canvas.drawCircle(x, y + size / 2, size / 2 + 10, circlePaint)
    }
    
    private fun drawDirectionMessage(canvas: Canvas, message: String, centerX: Float, centerY: Float) {
        val textBounds = Rect()
        textPaint.getTextBounds(message, 0, message.length, textBounds)
        
        val x = centerX - textBounds.width() / 2
        val y = centerY - 150
        
        canvas.drawText(message, x, y, textPaint)
        
        // Draw arrow icon
        val arrowSize = 50f
        if (message == "Move Left") {
            // Left arrow
            canvas.drawLine(centerX - arrowSize, centerY - 50, centerX - arrowSize / 2, centerY - 50, arrowPaint)
            canvas.drawLine(centerX - arrowSize / 2, centerY - 50, centerX - arrowSize / 2 - 20, centerY - 70, arrowPaint)
            canvas.drawLine(centerX - arrowSize / 2, centerY - 50, centerX - arrowSize / 2 - 20, centerY - 30, arrowPaint)
        } else {
            // Right arrow
            canvas.drawLine(centerX + arrowSize, centerY - 50, centerX + arrowSize / 2, centerY - 50, arrowPaint)
            canvas.drawLine(centerX + arrowSize / 2, centerY - 50, centerX + arrowSize / 2 + 20, centerY - 70, arrowPaint)
            canvas.drawLine(centerX + arrowSize / 2, centerY - 50, centerX + arrowSize / 2 + 20, centerY - 30, arrowPaint)
        }
    }
    
    private fun drawCompassInfo(canvas: Canvas, centerX: Float, centerY: Float, width: Float, height: Float) {
        val infoX = 20f
        val infoY = height - 40f
        
        val headingText = "You: ${currentHeading.toInt()}°"
        val qiblaText = "Qibla: ${qiblaBearing.toInt()}°"
        
        canvas.drawText(headingText, infoX, infoY, smallTextPaint)
        canvas.drawText(qiblaText, infoX, infoY + 40, smallTextPaint)
    }
}
