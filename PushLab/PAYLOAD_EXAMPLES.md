# Exemplos de Payloads

Este documento contém exemplos de payloads para cada tipo de push notification suportado pelo PushLab.

## 📱 Expo Notification

### Payload Básico
```json
{
  "to": ["ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]"],
  "title": "Hello from PushLab!",
  "body": "This is a test notification",
  "priority": "high"
}
```

### Payload com Custom Data
```json
{
  "to": ["ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]"],
  "title": "New Message",
  "body": "You have a new message",
  "data": {
    "screen": "chat",
    "messageId": "12345",
    "senderId": "user_abc"
  },
  "sound": "default",
  "badge": 1
}
```

### Payload com Android Specific
```json
{
  "to": ["ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]"],
  "title": "Delivery Update",
  "body": "Your package is arriving soon",
  "channelId": "delivery-updates",
  "ttl": 3600,
  "priority": "high"
}
```

---

## 🍎 APNs (Apple Push Notification service)

### Alert Notification
```json
{
  "aps": {
    "alert": {
      "title": "Breaking News",
      "subtitle": "World News",
      "body": "Major event happening right now"
    },
    "badge": 1,
    "sound": "default"
  }
}
```

### Background Notification
```json
{
  "aps": {
    "content-available": 1
  },
  "data": {
    "newContent": "true",
    "contentId": "article-123"
  }
}
```

### Notification with Category
```json
{
  "aps": {
    "alert": {
      "title": "Friend Request",
      "body": "John wants to connect with you"
    },
    "category": "FRIEND_REQUEST",
    "sound": "notification.wav"
  },
  "userId": "john_123"
}
```

---

## 🔴 Live Activity

### Start Live Activity
```json
{
  "aps": {
    "timestamp": 1711929600,
    "event": "update",
    "content-state": {
      "driverName": "John Doe",
      "estimatedDelivery": "15 min",
      "currentLocation": "5 stops away"
    },
    "alert": {
      "title": "Delivery Started",
      "body": "Your order is on the way"
    }
  }
}
```

### Update Live Activity
```json
{
  "aps": {
    "timestamp": 1711929900,
    "event": "update",
    "content-state": {
      "driverName": "John Doe",
      "estimatedDelivery": "5 min",
      "currentLocation": "2 stops away"
    }
  }
}
```

### End Live Activity
```json
{
  "aps": {
    "timestamp": 1711930200,
    "event": "end",
    "content-state": {
      "status": "delivered",
      "deliveryTime": "14:30"
    },
    "alert": {
      "title": "Delivered",
      "body": "Your package has been delivered"
    }
  }
}
```

### Sports Score Live Activity
```json
{
  "aps": {
    "timestamp": 1711929600,
    "event": "update",
    "content-state": {
      "homeTeam": "Warriors",
      "awayTeam": "Lakers",
      "homeScore": "98",
      "awayScore": "95",
      "quarter": "Q4",
      "timeRemaining": "2:45"
    }
  }
}
```

---

## 🤖 FCM (Firebase Cloud Messaging)

### Basic Notification
```json
{
  "message": {
    "token": "fcm_registration_token_here",
    "notification": {
      "title": "Hello FCM",
      "body": "This is a test notification"
    }
  }
}
```

### Data Message
```json
{
  "message": {
    "token": "fcm_registration_token_here",
    "data": {
      "action": "open_article",
      "articleId": "12345",
      "category": "technology"
    }
  }
}
```

### Notification with Android Config
```json
{
  "message": {
    "token": "fcm_registration_token_here",
    "notification": {
      "title": "New Update Available",
      "body": "Tap to install the latest version"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "app-updates",
        "sound": "notification_sound",
        "color": "#FF0000"
      }
    }
  }
}
```

### Notification with Data Payload
```json
{
  "message": {
    "token": "fcm_registration_token_here",
    "notification": {
      "title": "Payment Received",
      "body": "You received $50.00"
    },
    "data": {
      "transactionId": "txn_abc123",
      "amount": "50.00",
      "currency": "USD",
      "sender": "jane@example.com"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "payments",
        "color": "#4CAF50"
      }
    }
  }
}
```

---

## 🎯 Casos de Uso Específicos

### Deep Linking (Expo)
```json
{
  "to": ["ExponentPushToken[xxx]"],
  "title": "Check this out!",
  "body": "You've been mentioned in a post",
  "data": {
    "screen": "PostDetail",
    "postId": "post_789",
    "deepLink": "myapp://post/789"
  }
}
```

### E-commerce Order Update (APNs)
```json
{
  "aps": {
    "alert": {
      "title": "Order Shipped",
      "subtitle": "Order #12345",
      "body": "Your order has been shipped and is on the way"
    },
    "badge": 1,
    "sound": "shipment.wav"
  },
  "orderId": "12345",
  "trackingNumber": "TRK789456123",
  "estimatedDelivery": "2026-04-03"
}
```

### Ride Share ETA Update (Live Activity)
```json
{
  "aps": {
    "timestamp": 1711929600,
    "event": "update",
    "content-state": {
      "driverName": "Sarah Wilson",
      "carModel": "Toyota Camry",
      "licensePlate": "ABC-1234",
      "eta": "3 min",
      "distance": "0.5 mi",
      "pickupAddress": "123 Main St"
    }
  }
}
```

### Chat Message (FCM)
```json
{
  "message": {
    "token": "fcm_token",
    "notification": {
      "title": "Alice",
      "body": "Hey, are you free for lunch?"
    },
    "data": {
      "chatId": "chat_456",
      "senderId": "alice_123",
      "messageId": "msg_789",
      "timestamp": "1711929600"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "chat-messages",
        "sound": "message_tone",
        "tag": "chat_456"
      }
    }
  }
}
```

---

## 📋 Headers Examples

### Expo Headers
```
POST https://exp.host/--/api/v2/push/send
Content-Type: application/json
Authorization: Bearer YOUR_ACCESS_TOKEN (optional)
```

### APNs Headers
```
POST https://api.sandbox.push.apple.com/3/device/DEVICE_TOKEN
Content-Type: application/json
apns-topic: com.yourcompany.yourapp
apns-push-type: alert
authorization: bearer JWT_TOKEN
```

### Live Activity Headers
```
POST https://api.sandbox.push.apple.com/3/device/ACTIVITY_TOKEN
Content-Type: application/json
apns-topic: com.yourcompany.yourapp.push-type.liveactivity
apns-push-type: liveactivity
authorization: bearer JWT_TOKEN
```

### FCM Headers
```
POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send
Content-Type: application/json
Authorization: Bearer OAUTH_TOKEN
```

---

## 💡 Dicas

1. **Expo**: Use `priority: "high"` para notificações importantes
2. **APNs**: Background pushes não mostram alerta, use `content-available: 1`
3. **Live Activity**: Sempre inclua `timestamp` para garantir ordem correta
4. **FCM**: Use `channel_id` para categorizar notificações no Android

Para testar estes payloads, copie e cole os campos relevantes no PushLab!
