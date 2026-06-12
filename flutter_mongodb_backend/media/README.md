# Chatbot media

Files placed here are served publicly at `<PUBLIC_BASE_URL>/media/<filename>` and
can be sent to guests by the WhatsApp chatbot via the `send_media` tool.

The chatbot's media library is defined in `whatsapp_bot.js` (the `MEDIA` object).
By default it expects these files — drop the real ones in, or edit `MEDIA` to match:

| Key            | Expected file | Type     |
|----------------|---------------|----------|
| `rates_pdf`    | `rates.pdf`   | document |
| `room_photos`  | `rooms.jpg`   | image    |
| `hotel_photos` | `hotel.jpg`   | image    |
| `pool_photo`   | `pool.jpg`    | image    |

Until the real files are added, the bot still works — it just can't send those
items. Keep file sizes reasonable (WhatsApp limits: images ~5 MB, documents ~100 MB).
