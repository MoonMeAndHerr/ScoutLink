class AppConstants {
  // --- TEXT & BRANDING ---
  static const String appName = 'ScoutLink';
  static const String tagline = 'Where STEM Meets Adventure';

  // --- REGISTRATION CATEGORIES ---
  static const List<String> categories = ['IIUM Community', 'Public Community', 'School Group'];

  // --- LOCATION DATA ---
  static const List<String> campuses = ['Kuantan', 'Gambang', 'Gombak', 'Pagoh'];
  
  static const Map<String, List<String>> stateDistricts = {
    'Johor': ['Johor Bahru', 'Batu Pahat', 'Kluang', 'Kulai', 'Muar', 'Kota Tinggi', 'Segamat', 'Pontian', 'Tangkak', 'Mersing'],
    'Kedah': ['Baling', 'Bandar Baharu', 'Kota Setar', 'Kuala Muda', 'Kubang Pasu', 'Kulim', 'Langkawi', 'Padang Terap', 'Pendang', 'Pokok Sena', 'Sik', 'Yan'],
    'Kelantan': ['Bachok', 'Gua Musang', 'Jeli', 'Kota Bharu', 'Kuala Krai', 'Machang', 'Pasir Mas', 'Pasir Puteh', 'Tanah Merah', 'Tumpat'],
    'Melaka': ['Alor Gajah', 'Melaka Tengah', 'Jasin'],
    'Negeri Sembilan': ['Jelebu', 'Jempol', 'Kuala Pilah', 'Port Dickson', 'Rembau', 'Seremban', 'Tampin'],
    'Pahang': ['Bentong', 'Bera', 'Cameron Highlands', 'Jerantut', 'Kuantan', 'Lipis', 'Maran', 'Pekan', 'Raub', 'Rompin', 'Temerloh'],
    'Perak': ['Batang Padang', 'Hilir Perak', 'Hulu Perak', 'Kampar', 'Kerian', 'Kinta', 'Kuala Kangsar', 'Larut, Matang dan Selama', 'Manjung', 'Muallim', 'Perak Tengah', 'Bagan Datuk'],
    'Perlis': ['Perlis'],
    'Pulau Pinang': ['Timur Laut', 'Barat Daya', 'Seberang Perai Utara', 'Seberang Perai Tengah', 'Seberang Perai Selatan'],
    'Sabah': ['Beaufort', 'Beluran', 'Keningau', 'Kinabatangan', 'Kota Belud', 'Kota Kinabalu', 'Kota Marudu', 'Kuala Penyu', 'Kudat', 'Kunak', 'Lahad Datu', 'Nabawan', 'Papar', 'Penampang', 'Pitas', 'Putatan', 'Ranau', 'Sandakan', 'Semporna', 'Sipitang', 'Tambunan', 'Tawau', 'Tenom', 'Tongod', 'Tuaran'],
    'Sarawak': ['Asajaya', 'Bau', 'Belaga', 'Betong', 'Bintulu', 'Dalat', 'Daro', 'Julau', 'Kanowit', 'Kapit', 'Kuching', 'Lawas', 'Limbang', 'Lubok Antu', 'Lundu', 'Marudi', 'Matu', 'Meradong', 'Miri', 'Mukah', 'Samarahan', 'Saratok', 'Sarikei', 'Selangau', 'Serian', 'Sibu', 'Simunjan', 'Song', 'Sri Aman', 'Tatau'],
    'Selangor': ['Gombak', 'Hulu Langat', 'Hulu Selangor', 'Klang', 'Kuala Langat', 'Kuala Selangor', 'Petaling', 'Sabak Bernam', 'Sepang'],
    'Terengganu': ['Besut', 'Dungun', 'Hulu Terengganu', 'Kemaman', 'Kuala Nerus', 'Kuala Terengganu', 'Marang', 'Setiu'],
    'W.P. Kuala Lumpur': ['Kuala Lumpur'],
    'W.P. Labuan': ['Labuan'],
    'W.P. Putrajaya': ['Putrajaya']
  };

  // --- PERSONAL DETAILS ---
  static const List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const List<String> eatingHabits = ['Non-Vegetarian', 'Vegetarian'];
  static const List<String> genders = ['Male', 'Female'];
  static const List<String> ethnicities = ['Malay', 'Indian', 'Chinese', 'Others'];

  // --- SCOUTING & EVENTS ---
  static const List<String> scoutCats = ['Terbuka', 'Pengakap Kanak-Kanak (8-12 Tahun)', 'Pengakap Muda (13-15 Tahun)', 'Pengakap Remaja (16-17 Tahun)', 'Pengakap Kelana (18-25 Tahun)', 'Penolong Pemimpin', 'Pemimpin'];
  static const List<String> compChoices = ['Catapult Launcher', 'Balloon Car', 'Water Rocket'];
  static const List<String> slots = ['Session 1: 8AM-1030AM', 'Session 2: 1030AM-1PM'];
  static const List<String> teeSizes = ['None', 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL']; 

  // --- FEES & PACKAGES ---
  // We make the discounted string its own constant so we never typo it in the checklist logic!
  static const String discountedFee = 'STARK Carnival Discounted Price (RM35 without Woggle and Badges)';

  static const List<String> iiumFees = [
    'STARK Carnival (RM30)', 
    'Scout STEM Run (RM45)', 
    'Combo STARK Kit (RM72)'
  ];

  static const List<String> publicFees = [
    'STARK Carnival (RM55)', 
    discountedFee, 
    'Scout STEM Run (RM50)', 
    'Combo STARK Kit (RM100)'
  ];
}