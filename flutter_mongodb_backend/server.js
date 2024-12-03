const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Middlewaren
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
      booking.checkIn = req.body.checkIn; // Update check-in date
      booking.checkOut = req.body.checkOut; // Update check-out date

      // Automatically calculate the number of nights
      const checkInDate = new Date(req.body.checkIn);
      const checkOutDate = new Date(req.body.checkOut);
      booking.num_of_nights = (checkOutDate - checkInDate) / (1000 * 60 * 60 * 24);

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
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    await booking.remove();
    res.json({ message: 'Booking deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});


app.listen(port, "0.0.0.0",() => {
  console.log(`Server running on port http://15.207.116.36:3000`);
});





