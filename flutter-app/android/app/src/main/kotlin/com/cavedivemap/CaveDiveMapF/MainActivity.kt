package com.cavedivemap.CaveDiveMapF

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val uncalibratedChannel = "cavedivemap/uncalibrated_magnetometer"
    private var sensorManager: SensorManager? = null
    private var uncalibratedListener: SensorEventListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val uncalibratedSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, uncalibratedChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (uncalibratedSensor == null) {
                        events?.error("NO_SENSOR", "Uncalibrated magnetometer not available", null)
                        return
                    }
                    uncalibratedListener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            // event.values: [Bx, By, Bz, hardIronX, hardIronY, hardIronZ]
                            if (events == null) return
                            if (event.values.size >= 3) {
                                events.success(
                                    mapOf(
                                        "x" to event.values[0].toDouble(),
                                        "y" to event.values[1].toDouble(),
                                        "z" to event.values[2].toDouble()
                                    )
                                )
                            }
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    sensorManager?.registerListener(
                        uncalibratedListener,
                        uncalibratedSensor,
                        SensorManager.SENSOR_DELAY_GAME
                    )
                }

                override fun onCancel(arguments: Any?) {
                    uncalibratedListener?.let { sensorManager?.unregisterListener(it) }
                    uncalibratedListener = null
                }
            })
    }

    override fun onDestroy() {
        uncalibratedListener?.let { sensorManager?.unregisterListener(it) }
        uncalibratedListener = null
        super.onDestroy()
    }
}
