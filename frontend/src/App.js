import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import "./App.css";

// Contexts
import { AuthProvider } from "./contexts/AuthContext";
import { MediaPlayerProvider } from "./contexts/MediaPlayerContext";

// Layout Components
import Header from "./components/layout/Header";
import MediaPlayer from "./components/player/MediaPlayer";

// Pages
import Home from "./pages/Home";

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <MediaPlayerProvider>
          <div className="App min-h-screen bg-gray-900 text-white flex flex-col">
            <Header />
            
            <main className="flex-grow pt-16">
              <Routes>
                <Route path="/" element={<Home />} />
                {/* More routes will be added here */}
              </Routes>
            </main>
            
            <MediaPlayer />
          </div>
        </MediaPlayerProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
