/**
 * Analytics Service
 * Tracks and provides analytics data for the warehouse scanner app
 */

class AnalyticsService {
  constructor() {
    // In-memory storage for analytics
    // In production, you might want to use a database
    this.stats = {
      ordersScanned: 0,
      goodsScanned: 0,
      errorScans: {
        wrongProduct: 0,
        wrongTime: 0,
        total: 0
      },
      backendErrors: 0,
      lastUpdated: new Date().toISOString()
    };
    
    // Store daily stats for history
    this.dailyStats = {};
    
    // Initialize today's stats
    this._initializeToday();
  }

  _initializeToday() {
    const today = new Date().toISOString().split('T')[0];
    if (!this.dailyStats[today]) {
      this.dailyStats[today] = {
        ordersScanned: 0,
        goodsScanned: 0,
        errorScans: {
          wrongProduct: 0,
          wrongTime: 0,
          total: 0
        },
        backendErrors: 0
      };
    }
  }

  /**
   * Track a successful order scan (picking validation)
   */
  trackOrderScanned() {
    this.stats.ordersScanned++;
    this._initializeToday();
    this.dailyStats[this._getToday()].ordersScanned++;
    this.stats.lastUpdated = new Date().toISOString();
  }

  /**
   * Track a successful item scan
   */
  trackItemScanned() {
    this.stats.goodsScanned++;
    this._initializeToday();
    this.dailyStats[this._getToday()].goodsScanned++;
    this.stats.lastUpdated = new Date().toISOString();
  }

  /**
   * Track an error scan (wrong product or wrong time)
   */
  trackErrorScan(errorType) {
    this.stats.errorScans.total++;
    this._initializeToday();
    this.dailyStats[this._getToday()].errorScans.total++;
    
    if (errorType === 'WRONG_ORDER' || errorType === 'wrongProduct') {
      this.stats.errorScans.wrongProduct++;
      this.dailyStats[this._getToday()].errorScans.wrongProduct++;
    } else if (errorType === 'ZERO_QUANTITY' || errorType === 'wrongTime') {
      this.stats.errorScans.wrongTime++;
      this.dailyStats[this._getToday()].errorScans.wrongTime++;
    }
    
    this.stats.lastUpdated = new Date().toISOString();
  }

  /**
   * Track a backend error
   */
  trackBackendError() {
    this.stats.backendErrors++;
    this._initializeToday();
    this.dailyStats[this._getToday()].backendErrors++;
    this.stats.lastUpdated = new Date().toISOString();
  }

  /**
   * Get statistics for a specific period
   * @param {string} period - 'today', 'week', or 'custom'
   * @param {string} startDate - Start date (ISO string) for custom period
   * @param {string} endDate - End date (ISO string) for custom period
   */
  getStats(period = 'today', startDate = null, endDate = null) {
    let filteredStats = {
      ordersScanned: 0,
      goodsScanned: 0,
      errorScans: {
        wrongProduct: 0,
        wrongTime: 0,
        total: 0
      },
      backendErrors: 0
    };

    if (period === 'today') {
      const today = this._getToday();
      filteredStats = { ...this.dailyStats[today] } || filteredStats;
    } else if (period === 'week') {
      // Get last 7 days
      const last7Days = this._getLast7Days();
      last7Days.forEach(day => {
        filteredStats.ordersScanned += day.ordersScanned || 0;
        filteredStats.goodsScanned += day.goodsScanned || 0;
        filteredStats.errorScans.wrongProduct += day.errorScans?.wrongProduct || 0;
        filteredStats.errorScans.wrongTime += day.errorScans?.wrongTime || 0;
        filteredStats.errorScans.total += day.errorScans?.total || 0;
        filteredStats.backendErrors += day.backendErrors || 0;
      });
    } else if (period === 'custom' && startDate && endDate) {
      // Get custom date range
      const start = new Date(startDate);
      const end = new Date(endDate);
      
      // Iterate through all days in range
      const currentDate = new Date(start);
      while (currentDate <= end) {
        const dateStr = currentDate.toISOString().split('T')[0];
        const dayStats = this.dailyStats[dateStr];
        
        if (dayStats) {
          filteredStats.ordersScanned += dayStats.ordersScanned || 0;
          filteredStats.goodsScanned += dayStats.goodsScanned || 0;
          filteredStats.errorScans.wrongProduct += dayStats.errorScans?.wrongProduct || 0;
          filteredStats.errorScans.wrongTime += dayStats.errorScans?.wrongTime || 0;
          filteredStats.errorScans.total += dayStats.errorScans?.total || 0;
          filteredStats.backendErrors += dayStats.backendErrors || 0;
        }
        
        currentDate.setDate(currentDate.getDate() + 1);
      }
    } else if (period === 'all') {
      // Return all-time stats
      filteredStats = { ...this.stats };
    } else {
      // Default: return all-time stats
      filteredStats = { ...this.stats };
    }

    // Get daily breakdown for the selected period
    let dailyBreakdown = [];
    if (period === 'today') {
      const today = this._getToday();
      dailyBreakdown = [{
        date: today,
        ...(this.dailyStats[today] || {
          ordersScanned: 0,
          goodsScanned: 0,
          errorScans: { wrongProduct: 0, wrongTime: 0, total: 0 },
          backendErrors: 0
        })
      }];
    } else if (period === 'week') {
      dailyBreakdown = this._getLast7Days();
    } else if (period === 'custom' && startDate && endDate) {
      dailyBreakdown = this._getDateRange(startDate, endDate);
    } else if (period === 'all') {
      // For all-time, show last 30 days
      dailyBreakdown = this._getLast30Days();
    } else {
      dailyBreakdown = this._getLast7Days();
    }

    return {
      ...filteredStats,
      period: period,
      startDate: startDate,
      endDate: endDate,
      dailyStats: dailyBreakdown,
      lastUpdated: this.stats.lastUpdated
    };
  }

  /**
   * Get date range statistics
   */
  _getDateRange(startDate, endDate) {
    const days = [];
    const start = new Date(startDate);
    const end = new Date(endDate);
    const currentDate = new Date(start);
    
    while (currentDate <= end) {
      const dateStr = currentDate.toISOString().split('T')[0];
      days.push({
        date: dateStr,
        ...(this.dailyStats[dateStr] || {
          ordersScanned: 0,
          goodsScanned: 0,
          errorScans: { wrongProduct: 0, wrongTime: 0, total: 0 },
          backendErrors: 0
        })
      });
      currentDate.setDate(currentDate.getDate() + 1);
    }
    
    return days;
  }

  /**
   * Get today's date string
   */
  _getToday() {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * Get last 7 days of statistics
   */
  _getLast7Days() {
    const days = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      days.push({
        date: dateStr,
        ...(this.dailyStats[dateStr] || {
          ordersScanned: 0,
          goodsScanned: 0,
          errorScans: {
            wrongProduct: 0,
            wrongTime: 0,
            total: 0
          },
          backendErrors: 0
        })
      });
    }
    
    return days;
  }

  /**
   * Get last 30 days of statistics
   */
  _getLast30Days() {
    const days = [];
    const today = new Date();
    
    for (let i = 29; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      days.push({
        date: dateStr,
        ...(this.dailyStats[dateStr] || {
          ordersScanned: 0,
          goodsScanned: 0,
          errorScans: {
            wrongProduct: 0,
            wrongTime: 0,
            total: 0
          },
          backendErrors: 0
        })
      });
    }
    
    return days;
  }

  /**
   * Reset statistics (optional, for testing or periodic resets)
   */
  resetStats() {
    this.stats = {
      ordersScanned: 0,
      goodsScanned: 0,
      errorScans: {
        wrongProduct: 0,
        wrongTime: 0,
        total: 0
      },
      backendErrors: 0,
      lastUpdated: new Date().toISOString()
    };
    this.dailyStats = {};
    this._initializeToday();
  }
}

// Export singleton instance
module.exports = new AnalyticsService();

