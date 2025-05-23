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

// Updated Booking Schema
const bookingSchema = new mongoose.Schema({
  roomNumber: String,
  roomType: String,
  package: String,
  extraDetails: String,
  checkIn: Date,
  checkOut: Date,
  num_of_nights: Number, // New field to store the number of nights
  total : String,
  advance : String,
  balanceMethod :String
});

const Booking = mongoose.model('Booking', bookingSchema);

// Routes
app.get('/bookings', async (req, res) => {
  try {
    const bookings = await Booking.find();
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Routes
app.post('/bookings', async (req, res) => {
  const booking = new Booking({
    roomNumber: req.body.roomNumber,
    roomType: req.body.roomType,
    package: req.body.package,
    extraDetails: req.body.extraDetails,
    checkIn: req.body.checkIn, // Save check-in date
    checkOut: req.body.checkOut, // Save check-out date
    num_of_nights: req.body.num_of_nights, // Save number of nights
    total : req.body.total,
    advance : req.body.advance,
    balanceMethod: req.body.balanceMethod
  });

  try {
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
      package: req.body.package,
      extraDetails: req.body.extraDetails,
      checkIn: req.body.checkIn,
      checkOut: req.body.checkOut,
      ...(num_of_nights !== undefined && { num_of_nights }), // Add num_of_nights if calculated
      total : req.body.total,
      advance : req.body.advance,
      balanceMethod : req.body.balanceMethod
    };

    // Update booking
    const updatedBooking = await Booking.findOneAndUpdate(
      { _id: req.params.id },
      updateData,
      { new: true } // Return the updated document
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
  console.log(`Server running on port http://15.207.116.36:3000`);
});

app.get('/', (req, res) => {
    res.send('🟢 Server is running!');
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



