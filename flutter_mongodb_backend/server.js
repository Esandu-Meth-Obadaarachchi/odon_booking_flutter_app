require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const whatsappBot = require('./whatsapp_bot');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '15mb' })); // raised to allow base64 PDF uploads
app.use('/media', express.static(__dirname + '/media')); // chatbot media files

// Remove this line, as it's invalid JavaScript
// hello12345hello@cluster1

 //MongoDB connection
const dbURI = 'mongodb+srv://esandu123:hello12345hello@cluster1.wer9edk.mongodb.net/hotel?retryWrites=true&w=majority&appName=Cluster1';
mongoose.connect(dbURI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log(err));

const bookingSchema = new mongoose.Schema({
  roomNumber: String,   // legacy field (single-room bookings)
  roomType: String,     // legacy field (single-room bookings)
  rooms: [{             // new: one entry per room in the booking
    roomNumber: String,
    roomType: String,
    pax: Number,
  }],
  package: String,
  extraDetails: String,
  checkIn: Date,
  checkOut: Date,
  num_of_nights: Number,
  total: String,
  advance: String,
  balanceMethod: String,
  guestName: String,
  guestPhone: String,
  mealStart: String,  // 'Lunch' or 'Dinner' — first meal on arrival day for FB/HB
  needDriver: { type: Boolean, default: false },
});

const Booking = mongoose.model('Booking', bookingSchema);

// Guest Schema — phone is the unique identifier
const guestSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true, index: true },
  name:  { type: String, required: true },
}, { timestamps: true });

const Guest = mongoose.model('Guest', guestSchema);

// Helper: upsert a guest record from a booking. Skips if phone is missing.
async function upsertGuest(name, phone) {
  const cleanPhone = (phone || '').toString().trim();
  if (!cleanPhone) return; // no phone → not in guest db
  const cleanName = (name || '').toString().trim() || 'Guest';
  try {
    await Guest.findOneAndUpdate(
      { phone: cleanPhone },
      { $set: { name: cleanName }, $setOnInsert: { phone: cleanPhone } },
      { upsert: true, new: true }
    );
  } catch (e) {
    console.error('upsertGuest failed:', e.message);
  }
}

// RoomConfig Schema — single document, all rooms for the hotel
const roomConfigSchema = new mongoose.Schema({
  rooms: [{
    roomNumber: { type: String, required: true },
    baseType: { type: String, enum: ['Family', 'Double'], required: true },
    floor: { type: String, enum: ['Ground', 'Upper'], required: true },
    isBlocked: { type: Boolean, default: false },
  }],
});

const RoomConfig = mongoose.model('RoomConfig', roomConfigSchema);

const defaultRooms = [
  { roomNumber: '1',   baseType: 'Family', floor: 'Ground', isBlocked: false },
  { roomNumber: '2',   baseType: 'Double', floor: 'Ground', isBlocked: false },
  { roomNumber: '3',   baseType: 'Double', floor: 'Ground', isBlocked: false },
  { roomNumber: '4',   baseType: 'Double', floor: 'Ground', isBlocked: true  },
  { roomNumber: '5',   baseType: 'Family', floor: 'Ground', isBlocked: false },
  { roomNumber: '101', baseType: 'Family', floor: 'Upper',  isBlocked: false },
  { roomNumber: '102', baseType: 'Double', floor: 'Upper',  isBlocked: false },
  { roomNumber: '103', baseType: 'Double', floor: 'Upper',  isBlocked: false },
  { roomNumber: '104', baseType: 'Double', floor: 'Upper',  isBlocked: false },
  { roomNumber: '105', baseType: 'Double', floor: 'Upper',  isBlocked: false },
  { roomNumber: '106', baseType: 'Double', floor: 'Upper',  isBlocked: false },
  { roomNumber: '107', baseType: 'Family', floor: 'Upper',  isBlocked: false },
];

app.get('/room-config', async (req, res) => {
  try {
    let config = await RoomConfig.findOne();
    if (!config) {
      config = await RoomConfig.create({ rooms: defaultRooms });
    }
    res.json(config);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put('/room-config', async (req, res) => {
  try {
    let config = await RoomConfig.findOne();
    if (!config) {
      config = new RoomConfig({ rooms: req.body.rooms });
    } else {
      config.rooms = req.body.rooms;
    }
    const saved = await config.save();
    res.json(saved);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Routes
app.get('/bookings', async (req, res) => {
  try {
    const bookings = await Booking.find();
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// Salary Schema
const salarySchema = new mongoose.Schema({
  employeeName: { type: String, required: true },
  salaryType: { type: String, required: true }, // OT, Monthly, Weekly, Commission
  amount: { type: Number, required: true },
  date: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now }
});

const Salary = mongoose.model('Salary', salarySchema);

// Expense Schema
const expenseSchema = new mongoose.Schema({
  expenseName: { type: String, required: true },
  category: { type: String, required: true }, // Food, Utilities, Maintenance, etc.
  amount: { type: Number, required: true },
  date: { type: Date, required: true },
  reason: { type: String }, // Optional description
  createdAt: { type: Date, default: Date.now }
});

const Expense = mongoose.model('Expense', expenseSchema);
// Routes
app.post('/bookings', async (req, res) => {
  const booking = new Booking({
    roomNumber: req.body.roomNumber,
    roomType: req.body.roomType,
    rooms: req.body.rooms || [],
    package: req.body.package,
    extraDetails: req.body.extraDetails,
    checkIn: req.body.checkIn,
    checkOut: req.body.checkOut,
    num_of_nights: req.body.num_of_nights,
    total: req.body.total,
    advance: req.body.advance,
    balanceMethod: req.body.balanceMethod,
    guestName: req.body.guestName,
    guestPhone: req.body.guestPhone,
    mealStart: req.body.mealStart,
    needDriver: req.body.needDriver ?? false,
  });

  try {
    console.log('POST /bookings needDriver:', req.body.needDriver, '→', booking.needDriver);
    const newBooking = await booking.save();
    await upsertGuest(req.body.guestName, req.body.guestPhone);
    res.status(201).json(newBooking);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.put('/bookings/:id', async (req, res) => {
    console.log("updating product");
  try {
    // Calculate the number of nights if check-in and check-out are provided
    const checkInDate = new Date(req.body.checkIn);
    const checkOutDate = new Date(req.body.checkOut);
    const num_of_nights =
      req.body.checkIn && req.body.checkOut
        ? (checkOutDate - checkInDate) / (1000 * 60 * 60 * 24)
        : undefined;

    // Prepare the update data
    const updateData = {
      roomNumber: req.body.roomNumber,
      roomType: req.body.roomType,
      rooms: req.body.rooms,
      package: req.body.package,
      extraDetails: req.body.extraDetails,
      checkIn: req.body.checkIn,
      checkOut: req.body.checkOut,
      ...(num_of_nights !== undefined && { num_of_nights }),
      total: req.body.total,
      advance: req.body.advance,
      balanceMethod: req.body.balanceMethod,
      guestName: req.body.guestName,
      guestPhone: req.body.guestPhone,
      mealStart: req.body.mealStart,
      needDriver: req.body.needDriver ?? false,
    };

    console.log('PUT /bookings needDriver:', req.body.needDriver, '→', updateData.needDriver);

    // Update booking
    const updatedBooking = await Booking.findOneAndUpdate(
      { _id: req.params.id },
      { $set: updateData },
      { new: true }
    );

    if (!updatedBooking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    await upsertGuest(req.body.guestName, req.body.guestPhone);
    res.json(updatedBooking);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.delete('/bookings/:id', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    // Use deleteOne for the document
    await Booking.deleteOne({ _id: req.params.id });
    res.json({ message: 'Booking deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GUEST ROUTES

// One-time backfill: if guests collection is empty but bookings exist,
// extract distinct (phone, name) pairs from existing bookings.
async function backfillGuestsIfNeeded() {
  const guestCount = await Guest.estimatedDocumentCount();
  if (guestCount > 0) return;
  const bookings = await Booking.find({ guestPhone: { $exists: true, $nin: [null, ''] } });
  const seen = new Map();
  for (const b of bookings) {
    const phone = (b.guestPhone || '').toString().trim();
    if (!phone || seen.has(phone)) continue;
    seen.set(phone, { phone, name: (b.guestName || 'Guest').toString().trim() || 'Guest' });
  }
  if (seen.size === 0) return;
  try {
    await Guest.insertMany([...seen.values()], { ordered: false });
    console.log(`Backfilled ${seen.size} guests from existing bookings`);
  } catch (e) {
    console.error('Guest backfill error (continuing):', e.message);
  }
}

// List all guests with booking count + last booking date, most recent first
app.get('/guests', async (req, res) => {
  try {
    await backfillGuestsIfNeeded();
    const guests = await Guest.aggregate([
      {
        $lookup: {
          from: 'bookings',
          localField: 'phone',
          foreignField: 'guestPhone',
          as: 'bookings',
        },
      },
      {
        $project: {
          phone: 1,
          name: 1,
          createdAt: 1,
          updatedAt: 1,
          bookingCount: { $size: '$bookings' },
          lastBooking: { $max: '$bookings.checkIn' },
        },
      },
      { $sort: { lastBooking: -1, name: 1 } },
    ]);
    res.json(guests);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Search guests by name OR phone (case-insensitive prefix-ish match) — used for autocomplete
app.get('/guests/search', async (req, res) => {
  try {
    const q = (req.query.q || '').toString().trim();
    if (!q) return res.json([]);
    const safe = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // escape regex meta chars
    const regex = new RegExp(safe, 'i');
    const guests = await Guest.find({
      $or: [{ name: regex }, { phone: regex }],
    })
      .limit(10)
      .sort({ updatedAt: -1 });
    res.json(guests);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get a single guest by phone
app.get('/guests/:phone', async (req, res) => {
  try {
    const guest = await Guest.findOne({ phone: req.params.phone });
    if (!guest) return res.status(404).json({ message: 'Guest not found' });
    res.json(guest);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get all bookings for a guest (sorted most recent first)
app.get('/guests/:phone/bookings', async (req, res) => {
  try {
    const bookings = await Booking.find({ guestPhone: req.params.phone }).sort({ checkIn: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.listen(port, "0.0.0.0",() => {
  console.log(`Server is running on port http://15.207.116.36:3000`);
});

app.get('/', (req, res) => {
    res.send('🟢 Server is running boii!');
});

//////Run server on localhost
//app.listen(port, '192.168.1.26', () => {
//  console.log(`Server running on http://192.168.1.26:${port}`);
//});


// Inventory Schema
const inventorySchema = new mongoose.Schema({
  item_name: { type: String, required: true }, // Item name
  quantity: { type: Number, required: true, default: 0 }, // Quantity
  purchasedDate: Date,
  uploaded_time: { type: Date, default: Date.now }, // Timestamp of record creation/update
});

const Inventory = mongoose.model('Inventory', inventorySchema);


// Inventory Routes
// Get all inventory items
app.get('/inventory', async (req, res) => {
  try {
    const items = await Inventory.find();
    res.json(items);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Add or update an inventory item
app.post('/inventory', async (req, res) => {
  const { item_name, quantity, purchasedDate} = req.body;

  if (!item_name || quantity == null) {
    return res.status(400).json({ message: 'Item ID, name, and quantity are required' });
  }

  try {
    const existingItem = await Inventory.findOne({item_name});

    if (existingItem) {
      // If the item exists, update its quantity
      existingItem.quantity += quantity;
      existingItem.uploaded_time = Date.now();
      const updatedItem = await existingItem.save();
      existingItem.purchasedDate = purchasedDate;
      res.json(updatedItem);
    } else {
      // If the item doesn't exist, create a new record
      const newItem = new Inventory({
        item_name,
        quantity,
        purchasedDate
      });
      const savedItem = await newItem.save();
      res.status(201).json(savedItem);
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put('/inventory/:id', async (req, res) => {
  console.log("Updating inventory item");
  try {
    // Prepare the update data
    const updateData = {
      item_name: req.body.item_name,
      quantity: req.body.quantity,
      purchasedDate: req.body.purchasedDate
    };

    // Update inventory item
    const updatedInventoryItem = await Inventory.findOneAndUpdate(
      { _id: req.params.id },
      updateData,
      { new: true } // Return the updated document
    );

    if (!updatedInventoryItem) {
      return res.status(404).json({ message: 'Inventory item not found' });
    }

    res.json(updatedInventoryItem);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.delete('/inventory/:id', async (req, res) => {
  try {
    const inventory = await Inventory.findById(req.params.id);
    if (!Inventory) {
      return res.status(404).json({ message: 'inventory not found' });
    }

    // Use deleteOne for the document
    await Inventory.deleteOne({ _id: req.params.id });
    res.json({ message: 'Inventory deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});



// SALARY ROUTES

// Get all salary records
app.get('/salaries', async (req, res) => {
  try {
    const salaries = await Salary.find().sort({ createdAt: -1 });
    res.json(salaries);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Add new salary record
app.post('/salaries', async (req, res) => {
  const { employeeName, salaryType, amount } = req.body;

  if (!employeeName || !salaryType || !amount) {
    return res.status(400).json({ message: 'Employee name, salary type, and amount are required' });
  }

  const salary = new Salary({
    employeeName: req.body.employeeName,
    salaryType: req.body.salaryType,
    amount: req.body.amount,
    date: req.body.date || Date.now()
  });

  try {
    const newSalary = await salary.save();
    res.status(201).json(newSalary);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update salary record
app.put('/salaries/:id', async (req, res) => {
  console.log("Updating salary record");
  try {
    const updateData = {
      employeeName: req.body.employeeName,
      salaryType: req.body.salaryType,
      amount: req.body.amount,
      date: req.body.date
    };

    const updatedSalary = await Salary.findOneAndUpdate(
      { _id: req.params.id },
      updateData,
      { new: true }
    );

    if (!updatedSalary) {
      return res.status(404).json({ message: 'Salary record not found' });
    }

    res.json(updatedSalary);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete salary record
app.delete('/salaries/:id', async (req, res) => {
  try {
    const salary = await Salary.findById(req.params.id);
    if (!salary) {
      return res.status(404).json({ message: 'Salary record not found' });
    }

    await Salary.deleteOne({ _id: req.params.id });
    res.json({ message: 'Salary record deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// EXPENSE ROUTES

// Get all expense records
app.get('/expenses', async (req, res) => {
  try {
    const expenses = await Expense.find().sort({ createdAt: -1 });
    res.json(expenses);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Add new expense record
app.post('/expenses', async (req, res) => {
  const { expenseName, category, amount, date } = req.body;

  if (!expenseName || !category || !amount || !date) {
    return res.status(400).json({ message: 'Expense name, category, amount, and date are required' });
  }

  const expense = new Expense({
    expenseName: req.body.expenseName,
    category: req.body.category,
    amount: req.body.amount,
    date: req.body.date,
    reason: req.body.reason || ''
  });

  try {
    const newExpense = await expense.save();
    res.status(201).json(newExpense);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update expense record
app.put('/expenses/:id', async (req, res) => {
  console.log("Updating expense record");
  try {
    const updateData = {
      expenseName: req.body.expenseName,
      category: req.body.category,
      amount: req.body.amount,
      date: req.body.date,
      reason: req.body.reason
    };

    const updatedExpense = await Expense.findOneAndUpdate(
      { _id: req.params.id },
      updateData,
      { new: true }
    );

    if (!updatedExpense) {
      return res.status(404).json({ message: 'Expense record not found' });
    }

    res.json(updatedExpense);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete expense record
app.delete('/expenses/:id', async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.id);
    if (!expense) {
      return res.status(404).json({ message: 'Expense record not found' });
    }

    await Expense.deleteOne({ _id: req.params.id });
    res.json({ message: 'Expense record deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }

});


// Get expenses for a specific month
app.get('/expenses/month/:year/:month', async (req, res) => {
  try {
    const { year, month } = req.params;
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const expenses = await Expense.find({
      date: {
        $gte: startDate,
        $lte: endDate
      }
    }).sort({ date: -1 });

    res.json(expenses);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PRICE CONFIG

const priceConfigSchema = new mongoose.Schema({
  packages: { type: mongoose.Schema.Types.Mixed, required: true },
  driverRoomPrice: { type: Number, required: true },
}, { timestamps: true });

const PriceConfig = mongoose.model('PriceConfig', priceConfigSchema);

// Get prices (seeds defaults if none exist)
app.get('/prices', async (req, res) => {
  try {
    let config = await PriceConfig.findOne();
    if (!config) {
      config = new PriceConfig({ packages: DEFAULT_PACKAGE_PRICES, driverRoomPrice: 2500 });
      await config.save();
    }
    res.json(config);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update prices
app.put('/prices', async (req, res) => {
  try {
    let config = await PriceConfig.findOne();
    if (!config) {
      config = new PriceConfig({ packages: req.body.packages, driverRoomPrice: req.body.driverRoomPrice });
    } else {
      config.packages = req.body.packages;
      config.driverRoomPrice = req.body.driverRoomPrice;
      config.markModified('packages'); // required for Mixed type
    }
    await config.save();
    res.json(config);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Get salaries for a specific month
app.get('/salaries/month/:year/:month', async (req, res) => {
  try {
    const { year, month } = req.params;
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const salaries = await Salary.find({
      date: {
        $gte: startDate,
        $lte: endDate
      }
    }).sort({ date: -1 });

    res.json(salaries);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ─── WhatsApp: send an invoice PDF to a guest ──────────────────────────────
// Uses the WhatsApp Business Cloud API. Credentials come from env vars:
//   WHATSAPP_TOKEN                - permanent access token (Meta System User)
//   WHATSAPP_PHONE_NUMBER_ID      - the Cloud API phone number ID
//   WHATSAPP_TEMPLATE_NAME        - approved template name (default: invoice_send)
//   WHATSAPP_TEMPLATE_LANG        - template language code (default: en_US)
//   WHATSAPP_DEFAULT_COUNTRY_CODE - prepended to local numbers (default: 94)
const GRAPH_API_VERSION = 'v21.0';

// Normalises a phone number to WhatsApp's format: digits only, with country
// code, no leading '+' or '0'.
function normalizeWhatsAppPhone(raw) {
  let digits = (raw || '').toString().replace(/\D/g, '');
  const cc = (process.env.WHATSAPP_DEFAULT_COUNTRY_CODE || '94').replace(/\D/g, '');
  if (!digits) return '';
  if (digits.startsWith('00')) digits = digits.slice(2);          // 0094... -> 94...
  if (digits.startsWith('0')) digits = cc + digits.slice(1);      // 077... -> 9477...
  else if (!digits.startsWith(cc) && digits.length <= 9) digits = cc + digits;
  return digits;
}

app.post('/invoices/send-whatsapp', async (req, res) => {
  try {
    const { phone, guestName, pdfBase64, fileName } = req.body;

    const token = process.env.WHATSAPP_TOKEN;
    const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
    const templateName = process.env.WHATSAPP_TEMPLATE_NAME || 'invoice_send';
    const templateLang = process.env.WHATSAPP_TEMPLATE_LANG || 'en_US';

    if (!token || !phoneNumberId) {
      return res.status(500).json({
        message: 'WhatsApp is not configured on the server. Set WHATSAPP_TOKEN and WHATSAPP_PHONE_NUMBER_ID.',
      });
    }
    if (!pdfBase64) return res.status(400).json({ message: 'pdfBase64 is required' });

    const to = normalizeWhatsAppPhone(phone);
    if (!to) return res.status(400).json({ message: 'A valid guest phone number is required' });

    const safeFileName = (fileName || 'invoice.pdf').toString();

    // 1. Upload the PDF to the WhatsApp media endpoint -> media ID
    const pdfBuffer = Buffer.from(pdfBase64, 'base64');
    const form = new FormData();
    form.append('messaging_product', 'whatsapp');
    form.append('type', 'application/pdf');
    form.append('file', new Blob([pdfBuffer], { type: 'application/pdf' }), safeFileName);

    const uploadResp = await fetch(
      `https://graph.facebook.com/${GRAPH_API_VERSION}/${phoneNumberId}/media`,
      { method: 'POST', headers: { Authorization: `Bearer ${token}` }, body: form }
    );
    const uploadData = await uploadResp.json();
    if (!uploadResp.ok || !uploadData.id) {
      return res.status(502).json({
        message: 'Failed to upload the PDF to WhatsApp',
        details: uploadData.error || uploadData,
      });
    }

    // 2. Send the template message, with the uploaded PDF as the header document
    const messagePayload = {
      messaging_product: 'whatsapp',
      to,
      type: 'template',
      template: {
        name: templateName,
        language: { code: templateLang },
        components: [
          {
            type: 'header',
            parameters: [
              {
                type: 'document',
                document: { id: uploadData.id, filename: safeFileName },
              },
            ],
          },
          {
            type: 'body',
            parameters: [
              { type: 'text', text: (guestName || 'Guest').toString().trim() || 'Guest' },
            ],
          },
        ],
      },
    };

    const sendResp = await fetch(
      `https://graph.facebook.com/${GRAPH_API_VERSION}/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(messagePayload),
      }
    );
    const sendData = await sendResp.json();
    if (!sendResp.ok) {
      return res.status(502).json({
        message: 'WhatsApp rejected the message',
        details: sendData.error || sendData,
      });
    }

    res.json({
      success: true,
      to,
      messageId: sendData.messages && sendData.messages[0] && sendData.messages[0].id,
    });
  } catch (err) {
    console.error('send-whatsapp failed:', err);
    res.status(500).json({ message: err.message });
  }
});

// ─── WhatsApp chatbot webhook ──────────────────────────────────────────────
// GET verifies the webhook with Meta; POST receives incoming guest messages.
// See whatsapp_bot.js for the Claude-powered reply logic.
app.get('/whatsapp/webhook', whatsappBot.verifyWebhook);
app.post('/whatsapp/webhook', whatsappBot.handleIncomingMessage);
