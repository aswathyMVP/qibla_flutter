package com.example.qibla_finder

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlin.math.*
import com.example.qibla_finder.R

class ARViewActivity : AppCompatActivity(), SurfaceHolder.Callback, SensorEventListener, LocationListener {
    
    private lateinit var surfaceView: SurfaceView
    private lateinit var overlayView: AROverlayView
    private var sensorManager: SensorManager? = null
    private var locationManager: LocationManager? = null
    
    private var currentHeading = 0f
    private var qiblaBearing = 0f
    private var devicePitch = 0f
    
    private val accelerometer = FloatArray(3)
    private val magnetometer = FloatArray(3)
    private val rotationMatrix = FloatArray(9)
    private val orientationAngles = FloatArray(3)
    
    private var lastLocationUpdate = 0L
    private val LOCATION_UPDATE_INTERVAL = 5000L
    
    companion object {
        private const val PERMISSION_REQUEST_CODE = 100
        private const val CAMERA_PERMISSION = Manifest.permission.CAMERA
        private const val LOCATION_PERMISSION = Manifest.permission.ACCESS_FINE_LOCATION
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ar_view)
        
        qiblaBearing = intent.getFloatExtra("qibla_bearing", 0f)
        
        surfaceView = findViewById(R.id.surface_view)
        overlayView = findViewById(R.id.overlay_view)
        
        surfaceView.holder.addCallback(this)
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        checkPermissions()
        startSensorTracking()
        startLocationUpdates()
    }
    
    private fun checkPermissions() {
        val permissions = arrayOf(CAMERA_PERMISSION, LOCATION_PERMISSION)
        val permissionsToRequest = mutableListOf<String>()
        
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission)
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }
    
    private fun startSensorTracking() {
        val accelerometerSensor = sensorManager?.getDefaultSensor(android.hardware.Sensor.TYPE_ACCELEROMETER)
        val magnetometerSensor = sensorManager?.getDefaultSensor(android.hardware.Sensor.TYPE_MAGNETIC_FIELD)
        
        accelerometerSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        magnetometerSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }
    
    private fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(this, LOCATION_PERMISSION) == PackageManager.PERMISSION_GRANTED) {
            locationManager?.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                LOCATION_UPDATE_INTERVAL,
                0f,
                this
            )
        }
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        
        when (event.sensor.type) {
            android.hardware.Sensor.TYPE_ACCELEROMETER -> {
                System.arraycopy(event.values, 0, accelerometer, 0, 3)
            }
            android.hardware.Sensor.TYPE_MAGNETIC_FIELD -> {
                System.arraycopy(event.values, 0, magnetometer, 0, 3)
            }
        }
        
        SensorManager.getRotationMatrix(rotationMatrix, null, accelerometer, magnetometer)
        SensorManager.getOrientation(rotationMatrix, orientationAngles)
        
        currentHeading = Math.toDegrees(orientationAngles[0].toDouble()).toFloat()
        devicePitch = Math.toDegrees(orientationAngles[1].toDouble()).toFloat()
        
        if (currentHeading < 0) {
            currentHeading += 360
        }
        
        overlayView.updateHeading(currentHeading, qiblaBearing, devicePitch)
    }
    
    override fun onAccuracyChanged(sensor: android.hardware.Sensor?, accuracy: Int) {}
    
    override fun onLocationChanged(location: Location) {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastLocationUpdate < LOCATION_UPDATE_INTERVAL) {
            return
        }
        lastLocationUpdate = currentTime
        
        qiblaBearing = calculateQiblaBearing(location.latitude, location.longitude)
        overlayView.updateQiblaBearing(qiblaBearing)
    }
    
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
    
    private fun calculateQiblaBearing(latitude: Double, longitude: Double): Float {
        val kaabaLat = 21.4225
        val kaabaLon = 39.8262
        
        val lat1 = Math.toRadians(latitude)
        val lat2 = Math.toRadians(kaabaLat)
        val dLon = Math.toRadians(kaabaLon - longitude)
        
        val y = sin(dLon) * cos(lat2)
        val x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var bearing = Math.toDegrees(atan2(y, x)).toFloat()
        
        if (bearing < 0) {
            bearing += 360
        }
        
        return bearing
    }
    
    override fun surfaceCreated(holder: SurfaceHolder) {
        // Camera preview setup would go here
    }
    
    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}
    
    override fun surfaceDestroyed(holder: SurfaceHolder) {}
    
    override fun onDestroy() {
        super.onDestroy()
        sensorManager?.unregisterListener(this)
        locationManager?.removeUpdates(this)
    }
}
