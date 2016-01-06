
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define('hello', function(request, response) {
    response.success('Hello world!');
});

Parse.Cloud.define('getUserCommunities', function (request, response) {
    var query = new Parse.Query('Community');
    var user = request.params.user


    query.find().then(function(communities) {
        var results = [];

        var userIn = request.params.communities;
        for (var i = 0; i < communities.length; i++) {

        }
    })
});

Parse.Cloud.define('getLocalTasks', function(request, response) {
    var query = new Parse.Query('Posting');
    query.find().then(function(posts) {
        var results = [];

        for (var i = 0; i < posts.length; i++) {
            if (request.params.postLocation.milesTo(posts[i].get('postLocation')) < 100) {
                results.push(posts[i]);
            }
        }

        // success has been moved inside the callback for query.find()
        response.success(results);
    }, function(error) {
        // Make sure to catch any errors, otherwise you may see a 'success/error not called' error in Cloud Code.
        response.error('Could not retrieve Posts, error ' + error.code + ': ' + error.message);
    });
});

Parse.Cloud.define('getClaimedTasksForUser', function(request, response) {
    var query = new Parse.Query('Posting');
    query.find().then(function (posts) {
        var results = [],
            taskIndex;

        for (taskIndex = 0; taskIndex < posts.length; taskIndex++) {
            if (request.params.userId === posts[taskIndex].get('claimee')) {
                results.push(posts[taskIndex]);
            }
        }

        response.success(results);
    });
});

Parse.Cloud.define('getPostedTasksForUser', function(request, response) {
    var query = new Parse.Query('Posting');
    query.find().then(function (posts) {
        var results = [],
            taskIndex;

        for (taskIndex = 0; taskIndex < posts.length; taskIndex++) {
            if (request.params.userId === posts[taskIndex].get('poster')) {
                results.push(posts[taskIndex]);
            }
        }

        response.success(results);
    });
});


Parse.Cloud.define('getAverageContributionPerHour', function (req, res) {
    var query = new Parse.Query('Posting'),
        _getHoursAgo,
        _increaseArraySizeToFit;

        _getHoursAgo = function (dateOccurred) {
            var nowInMillis = new Date.getTime();
            return Math.round((nowInMillis - dateOccurred.getTime()) / 1000 / 60 / 60);
        };

        _increaseArraySizeToFit = function (array, size) {
            var index = array.length;
            for (index = array.length; index < size; index++) {
                array.push(0);
            }
        };

    query.equalTo('objectId', req.params.objectId);
    query.find().then(function (posts) {
        var totalMoneyAtEachHour = [],
            numPaymentsAtEachHour = [],
            post = posts.length === 1 ? posts[0] : '',
            payments,
            payment,
            paymentIndex,
            hoursAgoPaymentMade,
            averageMoneyAtEachHour;

        if (post) {
            payments = post.get('committedPayments');
            for (paymentIndex = 0; paymentIndex < payments.length; paymentIndex++) {
                payment = payments[paymentIndex];
                hoursAgoPaymentMade = _getHoursAgo(new Date(payment.get('event').get('date')));

                _increaseArraySizeToFit(numPaymentsAtEachHour, hoursAgoPaymentMade);
                _increaseArraySizeToFit(totalMoneyAtEachHour, hoursAgoPaymentMade);

                numPaymentsAtEachHour[hoursAgoPaymentMade] = 1 + numPaymentsAtEachHour[hoursAgoPaymentMade];
                totalMoneyAtEachHour[hoursAgoPaymentMade] = totalMoneyAtEachHour[hoursAgoPaymentMade] +
                        payment.get('amount');
            }

            for (paymentIndex = 0; paymentIndex < totalMoneyAtEachHour.length; paymentIndex++) {
                averageMoneyAtEachHour[paymentIndex] = totalMoneyAtEachHour[paymentIndex] / numPaymentsAtEachHour[paymentIndex];
            }

            res.success(averageMoneyAtEachHour);
        } else {
            res.error('no posting with that objectId');
        }
    });

});

Parse.Cloud.define('createBitcoinWallet', function (req, res) {
    var url = 'https://blockchain.info/api/v2/create_wallet?password=' + req.params.password + '&api_code=74c72cf4-9042-4d46-8506-3ceac4f862f9';
    Parse.Cloud.httpRequest({
      url: url,
      success: function(httpResponse) {
          var query = new Parse.Query(Parse.User);
          query.equalTo('username', req.params.username);
          query.find().then(function (results) {
             if (results.length > 0) {
                 results[0].set('guid', JSON.parse(httpResponse.text).guid);
                 results[0].set('address', JSON.parse(httpResponse.text).address);
                 results[0].set('walletPassword', req.params.password);
                 results[0].save();
             }
             res.success(httpResponse.text);
          });
      },
      error: function(httpResponse) {
        res.error('Request failed with response code ' + httpResponse.status + " url:" + url);
      }
    });
});

Parse.Cloud.define('getPriceOfPosting', function (req, res) {
    var query = new Parse.Query('Posting');
    query.get(req.params.objectId, {
      success: function(posting) {
          var payments = posting.get('committedPayments'),
          totalBounty = 0;
          payments.forEach(function (payment) {
              totalBounty = totalBounty + payment.get('amount');
          });
          res.success(totalBounty);
      },
      error: function(object, error) {
          res.error('we could not find a posting with that objectId');
      }
    });
});
