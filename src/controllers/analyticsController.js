const analyticsService = require('../services/analyticsService');

/**
 * @desc    Get analytics data
 * @route   GET /flf/api/v1/analytics
 * @access  Public (you might want to add auth later)
 * @query   period - 'today', 'week', or 'custom'
 * @query   startDate - Start date (ISO string) for custom period
 * @query   endDate - End date (ISO string) for custom period
 */
const getAnalytics = async (req, res) => {
  try {
    const { period = 'today', startDate, endDate } = req.query;
    
    // Validate period
    if (!['today', 'week', 'custom', 'all'].includes(period)) {
      return res.status(400).json({
        ok: false,
        error: 'Invalid period. Must be: today, week, custom, or all'
      });
    }
    
    // Validate custom date range
    if (period === 'custom') {
      if (!startDate || !endDate) {
        return res.status(400).json({
          ok: false,
          error: 'startDate and endDate are required for custom period'
        });
      }
      
      // Validate date format
      const start = new Date(startDate);
      const end = new Date(endDate);
      
      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        return res.status(400).json({
          ok: false,
          error: 'Invalid date format. Use ISO format (YYYY-MM-DD)'
        });
      }
      
      if (start > end) {
        return res.status(400).json({
          ok: false,
          error: 'startDate must be before or equal to endDate'
        });
      }
    }
    
    const stats = analyticsService.getStats(period, startDate, endDate);
    res.status(200).json({
      ok: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      error: 'Failed to get analytics',
      message: error.message
    });
  }
};

module.exports = {
  getAnalytics
};

