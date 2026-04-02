import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Star, MessageSquare, User, ThumbsUp, Calendar } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

export interface Review {
  id: string;
  author: string;
  rating: number;
  title: string;
  comment: string;
  date: Date;
  helpful: number;
  verified: boolean;
  category: 'bus' | 'restaurant' | 'hotel' | 'taxi';
}

interface ReviewsRatingsProps {
  entityId: string;
  entityName: string;
  entityType: 'bus' | 'restaurant' | 'hotel' | 'taxi';
  averageRating?: number;
  totalReviews?: number;
  reviews?: Review[];
  onSubmitReview?: (rating: number, title: string, comment: string) => void;
}

const ReviewsRatings = ({
  entityName,
  entityType,
  averageRating = 4.5,
  totalReviews = 128,
  reviews = [],
  onSubmitReview
}: ReviewsRatingsProps) => {
  const [showForm, setShowForm] = useState(false);
  const [userRating, setUserRating] = useState(0);
  const [title, setTitle] = useState('');
  const [comment, setComment] = useState('');

  const handleSubmit = () => {
    if (userRating && title && comment) {
      onSubmitReview?.(userRating, title, comment);
      setUserRating(0);
      setTitle('');
      setComment('');
      setShowForm(false);
    }
  };

  const getRatingColor = (rating: number) => {
    if (rating >= 4.5) return 'text-green-400';
    if (rating >= 3.5) return 'text-yellow-400';
    if (rating >= 2.5) return 'text-orange-400';
    return 'text-red-400';
  };

  const getRatingBgColor = (rating: number) => {
    if (rating >= 4.5) return 'bg-green-900/30';
    if (rating >= 3.5) return 'bg-yellow-900/30';
    if (rating >= 2.5) return 'bg-orange-900/30';
    return 'bg-red-900/30';
  };

  return (
    <div className="w-full space-y-6">
      <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm">
        <h3 className="text-white font-bold text-lg mb-4">Ratings & Reviews</h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className={cn(
            'bg-gradient-to-br rounded-lg p-4 border border-white/10',
            getRatingBgColor(averageRating)
          )}>
            <div className="text-4xl font-bold text-white mb-2">
              {averageRating.toFixed(1)}
            </div>
            <div className="flex gap-1 mb-2">
              {[...Array(5)].map((_, i) => (
                <Star
                  key={i}
                  className={cn(
                    'w-4 h-4',
                    i < Math.floor(averageRating)
                      ? getRatingColor(averageRating)
                      : 'text-gray-600'
                  )}
                  fill={i < Math.floor(averageRating) ? 'currentColor' : 'none'}
                />
              ))}
            </div>
            <p className="text-sm text-gray-300">{totalReviews} reviews</p>
          </div>

          <div className="space-y-2">
            <p className="text-white font-semibold mb-3">Rating Distribution</p>
            {[5, 4, 3, 2, 1].map((rating) => {
              const percentage = Math.floor(Math.random() * 40) + 20;
              return (
                <div key={rating} className="flex items-center gap-2">
                  <span className="text-xs text-gray-400 w-4">{rating}★</span>
                  <div className="flex-1 h-2 bg-white/10 rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${percentage}%` }}
                      transition={{ duration: 0.6 }}
                      className="h-full bg-gradient-to-r from-yellow-400 to-orange-400"
                    />
                  </div>
                  <span className="text-xs text-gray-400">{percentage}%</span>
                </div>
              );
            })}
          </div>

          <div className="flex flex-col justify-center">
            <Button
              onClick={() => setShowForm(!showForm)}
              className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white border-0"
            >
              <Star className="w-4 h-4 mr-2" />
              Write a Review
            </Button>
          </div>
        </div>
      </div>

      <AnimatePresence>
        {showForm && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="bg-gradient-to-br from-indigo-900/20 to-purple-900/20 border border-indigo-700/30 rounded-xl p-6 backdrop-blur-sm"
          >
            <h4 className="text-white font-semibold mb-4">Share Your Experience</h4>

            <div className="mb-4">
              <label className="text-sm text-gray-300 block mb-3">Your Rating</label>
              <div className="flex gap-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    onClick={() => setUserRating(star)}
                    className="p-1 transition transform hover:scale-110"
                  >
                    <Star
                      className={cn(
                        'w-8 h-8 transition',
                        star <= userRating ? 'text-yellow-400' : 'text-gray-600'
                      )}
                      fill={star <= userRating ? 'currentColor' : 'none'}
                    />
                  </button>
                ))}
              </div>
            </div>

            <div className="mb-4">
              <label className="text-sm text-gray-300 block mb-2">Review Title</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Summarize your experience..."
                className="w-full bg-slate-900/50 border border-white/10 rounded-lg px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50"
              />
            </div>

            <div className="mb-4">
              <label className="text-sm text-gray-300 block mb-2">Your Review</label>
              <textarea
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="What do you think about this service? Share your feedback..."
                rows={4}
                className="w-full bg-slate-900/50 border border-white/10 rounded-lg px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 resize-none"
              />
            </div>

            <div className="flex gap-3">
              <Button
                onClick={handleSubmit}
                className="flex-1 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white border-0"
              >
                Submit Review
              </Button>
              <Button
                onClick={() => setShowForm(false)}
                variant="ghost"
                className="text-gray-300 hover:text-white"
              >
                Cancel
              </Button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <div className="space-y-3">
        {reviews.length === 0 ? (
          <div className="text-center py-8">
            <MessageSquare className="w-12 h-12 text-gray-600 mx-auto mb-3 opacity-50" />
            <p className="text-gray-400">No reviews yet. Be the first to review!</p>
          </div>
        ) : (
          reviews.map((review, i) => (
            <motion.div
              key={review.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="bg-slate-800/30 border border-white/5 rounded-lg p-4 hover:bg-slate-800/50 transition"
            >
              <div className="flex items-start justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
                    <User className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <p className="text-white font-semibold text-sm">{review.author}</p>
                    <div className="flex items-center gap-2">
                      <div className="flex gap-1">
                        {[...Array(5)].map((_, i) => (
                          <Star
                            key={i}
                            className={cn(
                              'w-3 h-3',
                              i < review.rating ? 'text-yellow-400' : 'text-gray-600'
                            )}
                            fill={i < review.rating ? 'currentColor' : 'none'}
                          />
                        ))}
                      </div>
                      <span className="text-xs text-gray-400">{review.rating}.0</span>
                    </div>
                  </div>
                </div>
                {review.verified && (
                  <span className="text-xs bg-green-900/30 text-green-300 px-2 py-1 rounded">
                    ✓ Verified
                  </span>
                )}
              </div>

              <h5 className="text-white font-semibold text-sm mb-2">{review.title}</h5>
              <p className="text-gray-300 text-sm mb-3">{review.comment}</p>

              <div className="flex items-center justify-between text-xs text-gray-400">
                <div className="flex items-center gap-1">
                  <Calendar className="w-3 h-3" />
                  {review.date.toLocaleDateString()}
                </div>
                <button className="flex items-center gap-1 hover:text-blue-400 transition">
                  <ThumbsUp className="w-3 h-3" />
                  Helpful ({review.helpful})
                </button>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
};

export default ReviewsRatings;
