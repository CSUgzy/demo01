package com.liangshiyiyou.app;

import androidx.multidex.MultiDexApplication;
import android.content.Context;
import android.util.Log;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MyApplication extends MultiDexApplication {
    private static final String TAG = "LiangshiyiyouApp";
    private static Context context;

    @Override
    public void onCreate() {
        super.onCreate();
        context = getApplicationContext();
        
        // 设置全局异常处理器
        Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
            @Override
            public void uncaughtException(Thread thread, Throwable ex) {
                handleUncaughtException(thread, ex);
            }
        });
        
        Log.i(TAG, "应用初始化完成");
    }
    
    /**
     * 处理未捕获的异常
     */
    private void handleUncaughtException(Thread thread, Throwable ex) {
        Log.e(TAG, "发生未捕获异常: " + ex.getMessage());
        
        // 获取异常堆栈信息
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        ex.printStackTrace(pw);
        String stackTrace = sw.toString();
        
        // 记录到文件
        writeErrorToFile(stackTrace);
        
        // 结束应用
        android.os.Process.killProcess(android.os.Process.myPid());
        System.exit(1);
    }
    
    /**
     * 将错误信息写入文件
     */
    private void writeErrorToFile(String errorMsg) {
        try {
            // 创建日志目录
            File logDir = new File(getExternalFilesDir(null), "crash_logs");
            if (!logDir.exists()) {
                logDir.mkdirs();
            }
            
            // 创建日志文件，使用时间戳命名
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault());
            String fileName = "crash_" + sdf.format(new Date()) + ".txt";
            File logFile = new File(logDir, fileName);
            
            // 写入错误信息
            FileOutputStream fos = new FileOutputStream(logFile);
            fos.write(("时间: " + new Date().toString() + "\n").getBytes());
            fos.write(("错误: " + errorMsg + "\n").getBytes());
            fos.close();
            
            Log.i(TAG, "错误日志已保存到: " + logFile.getAbsolutePath());
        } catch (IOException e) {
            Log.e(TAG, "写入错误日志失败: " + e.getMessage());
        }
    }
    
    public static Context getAppContext() {
        return context;
    }
} 