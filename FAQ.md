## 🔧 FAQ: Setup & Operation Guide for OPEN Stereo

### 1. What is the correct order for powering on the system?

Turn on all hardware in the following order:

1. **Prior Controller Box** – ensure it is powered and connected.  
2. **Microscope** – power on and confirm proper light source if needed.  
3. **Computer & Display** – boot up and log into your workstation.

---

### 2. When should fluorescence be enabled?

- Only enable fluorescence when required for your imaging session (e.g., DAPI, FITC).
- For brightfield-only sessions, leave fluorescence off to preserve bulb life and reduce noise.

---

### 3. How do I verify the Prior Terminal is connected properly?

**For Windows systems**:

1. Launch **Prior Terminal x64**.  
2. Ensure `COM1` is selected and connect at `9600` baud.  
3. If no response from the `date` command:
   - Set `Baud=96`
   - Click **Disconnect**
   - Click **Connect**
   - Retry the `date` command  
4. If you receive a response:
   - Set `Baud=38`
   - Disconnect again, then connect at `38400` baud  
   - Confirm with another `date` command  
5. Close the terminal after successful connection.

💡 *This ensures MATLAB or other control software can communicate with the Prior stage.*

---

### 4. How do I configure the YawCam software?

- Confirm YawCam version: `0.5.0` (2016-01-31 build).
- In YawCam:
  - Enable **HTTP** under the “Settings” menu.
  - Adjust camera parameters to match the selected imaging mode (e.g., DAPI, FITC, Brightfield).
- Use **ToupView** to configure camera behavior if it overrides YawCam settings.

---

### 5. What if the image feed or control software isn’t responding?

- Reboot the **YawCam** software.
- Verify HTTP stream is enabled and running.
- Ensure camera is connected and visible in **Device Manager**.
- Double-check that:
  - **Prior Terminal** is configured
  - **MATLAB/Imaging software** has access
