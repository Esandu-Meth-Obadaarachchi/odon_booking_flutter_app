const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

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
