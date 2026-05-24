# Deployment Guide - Bishkek Courier Vision

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git
- OpenAI API Key

## Quick Start (Development)

### 1. Clone Repository

```bash
git clone https://github.com/your-team/bishkek-courier-vision.git
cd bishkek-courier-vision
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your OpenAI API key
nano .env
```

### 3. Start Services

```bash
# Build and start all containers
docker-compose up --build -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Verify Services

```bash
# Backend health check
curl http://localhost:8000/api/health

# AI Service health check
curl http://localhost:5000/ai/health

# Nginx health check
curl http://localhost/health
```

### 5. Initialize Database

Database is automatically initialized with schema and seed data on first run.

To manually reset:

```bash
docker-compose exec mysql mysql -uroot -prootpassword bishkek_courier < docker/mysql/init/01-schema.sql
```

---

## Mobile App Setup

### Flutter Installation

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Run on iOS (Mac only)
flutter run -d ios

# Build APK
flutter build apk --release
```

### Configure API URL

Edit `mobile/lib/services/api_service.dart`:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:8000/api';

// For real device (use your machine's IP)
static const String baseUrl = 'http://192.168.1.100:8000/api';
```

---

## Production Deployment

### Environment Variables

```bash
# Production .env
DB_HOST=your-mysql-host
DB_NAME=bishkek_courier
DB_USER=courierapp
DB_PASSWORD=your-secure-password

OPENAI_API_KEY=your-api-key

JWT_SECRET=your-very-secure-jwt-secret-key

# AI Configuration
MIN_CONFIDENCE_THRESHOLD=0.75
MAX_IMAGE_SIZE_MB=10
```

### Docker Compose Production

```bash
# Use production compose file
docker-compose -f docker-compose.prod.yml up -d
```

### SSL/HTTPS Setup

Add Nginx SSL configuration:

```nginx
server {
    listen 443 ssl http2;
    server_name api.bishkekcourier.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # ... rest of config
}
```

---

## Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f ai_service

# AI decisions log
tail -f logs/ai/ai_decisions.log
```

### Health Checks

```bash
# Backend
curl http://localhost:8000/api/health

# AI Service
curl http://localhost:5000/ai/health

# AI Statistics
curl http://localhost:5000/ai/statistics
```

### Performance Monitoring

Check response time headers:

```bash
curl -I http://localhost:8000/api/addresses
# Look for: X-Response-Time header
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]

# Rebuild and restart
docker-compose up --build -d [service-name]
```

### Database Connection Issues

```bash
# Check MySQL is running
docker-compose exec mysql mysql -uroot -prootpassword -e "SELECT 1"

# Verify network
docker network inspect bishkek-courier-vision_courier_network
```

### AI Service Issues

```bash
# Verify OpenAI API key
docker-compose exec ai_service python -c "import os; print(os.getenv('OPENAI_API_KEY'))"

# Check AI service logs
docker-compose logs ai_service | grep -i error
```

### Mobile App Can't Connect

1. Check API URL in `api_service.dart`
2. Verify backend is accessible from device
3. Check firewall settings
4. For Android: ensure `android:usesCleartextTraffic="true"` in AndroidManifest.xml for development

---

## Backup and Restore

### Backup Database

```bash
docker-compose exec mysql mysqldump -uroot -prootpassword bishkek_courier > backup.sql
```

### Restore Database

```bash
docker-compose exec -T mysql mysql -uroot -prootpassword bishkek_courier < backup.sql
```

### Backup Uploaded Files

```bash
docker cp bcv_backend:/var/www/html/storage/uploads ./backups/uploads-$(date +%Y%m%d)
```

---

## Scaling

### Horizontal Scaling

```bash
# Scale AI service (multiple instances)
docker-compose up -d --scale ai_service=3

# Use load balancer (Nginx already configured)
```

### Database Optimization

```sql
-- Add indexes for performance
CREATE INDEX idx_contributions_user ON contributions(user_id, created_at);
CREATE INDEX idx_addresses_location ON addresses(latitude, longitude);
```

---

## Security Checklist

- [ ] Change default passwords
- [ ] Set strong JWT secret
- [ ] Enable HTTPS/SSL
- [ ] Configure firewall rules
- [ ] Regular security updates
- [ ] Backup OpenAI API key securely
- [ ] Enable rate limiting
- [ ] Review logs regularly
- [ ] Implement authentication for admin endpoints

---

## Cost Optimization

### OpenAI API Costs

- Average cost per image verification: ~$0.01
- Use caching to reduce duplicate calls (60% cache hit rate)
- Resize images before sending (saves 40% costs)
- Monitor usage: `curl http://localhost:5000/ai/statistics`

### Server Resources

- Minimum: 2 vCPU, 4GB RAM
- Recommended: 4 vCPU, 8GB RAM
- Storage: 20GB+ for images

---

## Support

- Documentation: `/docs`
- API Docs: `/backend/API_DOCS.md`
- Issues: GitHub Issues
- Team: [Your team contact]