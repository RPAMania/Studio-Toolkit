DROP TABLE IF EXISTS SpeechRecognitionActivity;

CREATE TABLE IF NOT EXISTS SpeechRecognitionActivity(
  id INTEGER PRIMARY KEY AUTOINCREMENT, 
  version TEXT NOT NULL,
  name TEXT NOT NULL,
  xml TEXT NOT NULL,
  UNIQUE (version, name)
);