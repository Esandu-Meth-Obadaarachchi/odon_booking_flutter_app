const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 1000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// MongoDB connection
const dbURI = 'mongodb+srv://esandu123:hello12345hello@cluster1.wer9edk.mongodb.net/hotel?retryWrites=true&w=majority&appName=Cluster1';
mongoose.connect(dbURI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log(err));

// Booking Schema
const bookingSchema = new mongoose.Schema({
  roomNumber: String,
  roomType: String,
  package: String,
  extraDetails: String,
  date: Date
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

app.post('/bookings', async (req, res) => {
  const booking = new Booking({
    roomNumber: req.body.roomNumber,
    roomType: req.body.roomType,
    package: req.body.package,
    extraDetails: req.body.extraDetails,
    date: req.body.date
  });

  try {
    const newBooking = await booking.save();
    res.status(201).json(newBooking);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.put('/bookings/:id', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (booking) {
      booking.roomNumber = req.body.roomNumber;
      booking.roomType = req.body.roomType;
      booking.package = req.body.package;
      booking.extraDetails = req.body.extraDetails;
      booking.date = req.body.date;
      const updatedBooking = await booking.save();
      res.json(updatedBooking);
    } else {
      res.status(404).json({ message: 'Booking not found' });
    }
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.delete('/bookings/:id', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (booking) {
      await booking.remove();
      res.json({ message: 'Booking deleted' });
    } else {
      res.status(404).json({ message: 'Booking not found' });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
