"""Rebuild the static download QR and printable poster. No tracking service."""
from pathlib import Path
from PIL import Image, ImageDraw
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader

URL = 'https://bkkcommunity-platform-2-production.up.railway.app/download.php'
OUT = Path(__file__).resolve().parents[1] / 'public' / 'assets' / 'downloads'
OUT.mkdir(parents=True, exist_ok=True)
qr = QrCodeWidget(URL, barLevel='M')
qr.qr.make()
count = qr.qr.getModuleCount()
quiet = 4
scale = 20
pixels = (count + 2 * quiet) * scale
image = Image.new('RGB', (pixels, pixels), 'white')
draw = ImageDraw.Draw(image)
for row in range(count):
    for col in range(count):
        if qr.qr.isDark(row, col):
            x, y = (col + quiet) * scale, (row + quiet) * scale
            draw.rectangle((x, y, x + scale - 1, y + scale - 1), fill='#153B5A')
png = OUT / 'bkk-android-download-qr.png'
image.save(png)

pdf = OUT / 'bkk-android-download-qr.pdf'
w, h = A4
c = canvas.Canvas(str(pdf), pagesize=A4)
c.setTitle('BKK Community - Scan to download the Android app')
c.setAuthor('BKK Community Group')
c.setFillColor(HexColor('#1F4E79'))
c.rect(0, h - 134, w, 134, stroke=0, fill=1)
c.setFillColor(white)
c.setFont('Helvetica-Bold', 26)
c.drawCentredString(w / 2, h - 62, 'BKK COMMUNITY')
c.setFont('Helvetica', 17)
c.drawCentredString(w / 2, h - 94, 'Get the Android app')
c.setFillColor(HexColor('#153B5A'))
c.setFont('Helvetica-Bold', 24)
c.drawCentredString(w / 2, h - 185, 'Scan with your phone camera')
side = 315
c.drawImage(ImageReader(image), (w - side) / 2, h - 525, side, side, mask='auto')
c.setFont('Helvetica', 14)
c.drawCentredString(w / 2, h - 562, 'Open the link, then tap Download Android APK.')
c.drawCentredString(w / 2, h - 587, 'Android 8 or newer. Installation steps are on the page.')
c.setFont('Helvetica', 11)
c.drawCentredString(w / 2, h - 630, 'Signed testing APK - not a Google Play release.')
c.drawCentredString(w / 2, h - 650, 'Using an iPhone? Use the website instead.')
c.setFont('Helvetica', 10)
c.drawCentredString(w / 2, 90, 'Or type this address into your browser:')
c.setFont('Helvetica-Bold', 9)
c.drawCentredString(w / 2, 72, URL)
c.linkURL(URL, ((w - side) / 2, h - 525, (w + side) / 2, h - 525 + side), relative=0)
c.save()
print(png)
print(pdf)
