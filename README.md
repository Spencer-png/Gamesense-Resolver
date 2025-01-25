# Machine Learning Resolver (MLR)

A Lua-based Machine Learning Resolver for game environments that support Lua scripting, designed to analyze and counter player behavior dynamically. This resolver leverages machine learning to optimize in-game performance by tracking player data, predicting movements, and resolving angles based on both real-time inputs and server-side feedback.

---

## Features

- **Machine Learning Integration**  
  Communicates with a local HTTP server to process player data and receive predictions to resolve angles effectively.

- **Player Tracking**  
  Records detailed player information, including:
  - Simulation times
  - Eye angles
  - Desync history
  - Missed shots
  - Hitbox positions

- **Dynamic Angle Adjustment**  
  Dynamically adjusts angles based on learned data from the server and past behavior records.

- **Shooting Event Handling**  
  Tracks shots fired, logs hits and misses, and adjusts player records accordingly.

- **Regular Updates**  
  Updates tracked players every 0.1 seconds to minimize performance impact.

---

## Setup and Requirements

1. **Environment**  
   - Requires a Lua scripting host that supports `gamesense/http` and `json` libraries.  

2. **Local HTTP Server**  
   - A local HTTP server must be running on `http://127.0.0.1:8080` to process machine learning data.  
   - Without the server, the resolver will not function properly.

3. **Game Compatibility**  
   - Designed for game environments with scripting capabilities and APIs like:
     - `entity.get_players`
     - `entity.hitbox_position`
     - `plist.set`

---

## How It Works

1. **Initialization**  
   - The script loads required libraries and displays user-friendly logs, including:
     - Confirmation: **"Machine Learning Resolver Successfully Loaded!"**
     - Warning: **"Don't forget to start your local HTTP server."**

2. **Player Data Management**  
   - Tracks player activity, maintaining up-to-date records on desync history, missed shots, and angles.
   - Limits stored data to optimize performance (e.g., 8 recent angle records per player).

3. **Angle Resolution**  
   - Calculates desync angle deltas and sends data to the HTTP server.
   - Adjusts angles dynamically using server feedback (`learned side`) for enhanced accuracy.

4. **Shooting Events**  
   - Logs shot events, including whether they hit or missed, and updates the resolver’s prediction strategy accordingly.

5. **Periodic Updates**  
   - Updates tracked players and resolves angles at 0.1-second intervals to maintain performance without overloading.

---

## Example Logs

- **On Load**:  
  ```
  [MLR] Machine Learning Resolver Successfully Loaded!, Coded by Spencer
  [MLR] Don't forget to start your local HTTP server
  ```

- **HTTP Server Communication**:  
  - Sends player behavior data (desync history, missed shots, etc.) for processing.  
  - Receives `learned_side` prediction to refine angle resolution.

---

## Important Notes

- **Intended Use**:  
  Fuck ai for putting this bullshit smh 
  This script is for **educational or personal use only**. Avoid using it in competitive settings or to gain unfair advantages.  

- **Compliance**:  
  WOMP WOMP FUCK this do what ever the fuck u want AHAHAHHAA
  Ensure adherence to your game’s terms of service to prevent penalties or bans.

---

## License

This project is open for personal and educational use. Any misuse is the responsibility of the user.

