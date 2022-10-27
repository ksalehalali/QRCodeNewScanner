using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using AForge;
using AForge.Video;
using AForge.Video.DirectShow;

using ZXing;
using ZXing.Aztec;
using RestSharp;
using System.Net;
using Newtonsoft.Json.Linq;

namespace QRCodeNewScanner
{
    public partial class Form1 : Form
    {
        private FilterInfoCollection CaptureDevice;
        private VideoCaptureDevice FinalFram;



        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            CaptureDevice = new FilterInfoCollection(FilterCategory.VideoInputDevice);
            foreach (FilterInfo Device in CaptureDevice)
                comboBox1.Items.Add(Device.Name);

            comboBox1.SelectedIndex = 0;
            FinalFram = new VideoCaptureDevice();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            FinalFram = new VideoCaptureDevice(CaptureDevice[comboBox1.SelectedIndex].MonikerString);
            FinalFram.NewFrame += new NewFrameEventHandler(FinalFrame_NewFrame);
            GetQRCode();
            FinalFram.Start();
        }

        private void FinalFrame_NewFrame(object sender, NewFrameEventArgs eventArgs)
        {
            pictureBox1.Image = (Bitmap)eventArgs.Frame.Clone();

        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (FinalFram.IsRunning == true)
                FinalFram.Stop();
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            BarcodeReader reader = new BarcodeReader();
            Result result = reader.Decode((Bitmap)pictureBox1.Image);

            try
            {
               if(result != null)
                {
                    string decoded = result.ToString().Trim();
                    if (decoded != "")
                    {
                        textBox1.Text = decoded;
                    }
                }
            }
            catch (Exception)
            {

                throw;
            }
        }

        private void GetQRCode()
        {

            using (var client = new RestClient("https://route.click68.com/api/QRCode"))
            {
                var payload = new JObject();
                payload.Add("Longitude", 121);
                payload.Add("Latitude", 1234545);

                var request = new RestRequest();
                request.AddStringBody(payload.ToString(), DataFormat.Json);
                request.AddHeader("Authorization", "bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJOYW1lIjoiOTY1OTg4MjQ1NjciLCJSb2xlIjoiVXNlciIsImV4cCI6MTY2Njg3NzAxNCwiaXNzIjoiSW52ZW50b3J5QXV0aGVudGljYXRpb25TZXJ2ZXIiLCJhdWQiOiJJbnZlbnRvcnlTZXJ2aWNlUG90bWFuQ2xpZW50In0.T0yavhTrTVtQGjTPFCsooWw3i4sCoefgnSojqqKzgLY");
                var result = client.PostAsync(request).Result;

                Console.WriteLine($"res:: " + result.Content);

                //Pay($"{result.Content}");

            }

        }

        private void Pay(string message)
        {
            using (var client = new RestClient("https://route.click68.com/api/Pay"))
            {
                var payload = new JObject();
                payload.Add("api_key", "$FhlF]3;.OIic&{>H;_DeW}|:wQ,A8");
                payload.Add("api_secret", "Z~P7-_/i!=}?BIwAd*S67LBzUo4O^G");
                payload.Add("Value", 0.350);
                payload.Add("PlateNumber", "454545");
                payload.Add("Message", message);
              

                var request = new RestRequest();
                request.AddStringBody(payload.ToString(), DataFormat.Json);
               // request.AddHeader("Authorization", "bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJOYW1lIjoiOTY1OTg4MjQ1NjciLCJSb2xlIjoiVXNlciIsImV4cCI6MTY2Njg3NzAxNCwiaXNzIjoiSW52ZW50b3J5QXV0aGVudGljYXRpb25TZXJ2ZXIiLCJhdWQiOiJJbnZlbnRvcnlTZXJ2aWNlUG90bWFuQ2xpZW50In0.T0yavhTrTVtQGjTPFCsooWw3i4sCoefgnSojqqKzgLY");
                var result = client.PostAsync(request).Result;

                Console.WriteLine($"res:: " + result.Content);

            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            timer1.Start();
        }
    }
}
