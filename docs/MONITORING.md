# 📊 Monitoring Guide

## Real-time Monitoring

### View All Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f ai_service
docker-compose logs -f mysql
docker-compose logs -f nginx
```

### Check Container Status
```bash
docker-compose ps
docker stats
```

### Service Health
```bash
# Backend
curl http://localhost:8000/api/health

# AI Service
curl http://localhost:5000/ai/health

# AI Statistics
curl http://localhost:5000/ai/statistics
```

---

## Performance Metrics

### Response Times
Look for `X-Response-Time` header in API responses

### AI Service Stats
```bash
curl http://localhost:5000/ai/statistics
```

Returns:
- Total requests
- Cache hit rate
- Average confidence
- Token usage

### Database Performance
```bash
# Connect to MySQL
docker-compose exec mysql mysql -uroot -prootpassword bishkek_courier

# Check slow queries
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Slow_queries';
```

---

## Troubleshooting

### Container Won't Start
```bash
docker-compose logs [service-name] --tail 50
docker-compose restart [service-name]
```

### Out of Disk Space
```bash
docker system prune -a
docker volume prune
```

### Memory Issues
```bash
docker stats
docker-compose down
docker-compose up -d
```

---

## Backup

### Database Backup
```bash
docker-compose exec mysql mysqldump -uroot -prootpassword bishkek_courier > backup-$(date +%Y%m%d).sql
```

### Restore
```bash
docker-compose exec -T mysql mysql -uroot -prootpassword bishkek_courier < backup.sql
```