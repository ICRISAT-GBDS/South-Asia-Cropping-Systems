//Map.addLayer(cropmask)
var ndvi = ee.ImageCollection("COPERNICUS/S2_HARMONIZED")
  .filterBounds(geometry)
  .map(function(image) {
    return image.select().addBands(image.normalizedDifference(['B8', 'B4']));
  });

// start and end date
var startDate = ee.Date('20xx-06-01');
var endDate = ee.Date('20xx-05-30');

// interval
var interval = 1;

// Calculating number of intervals
var numberOfIntervals = endDate.difference(startDate,'month').divide(interval).toInt();

// Generating a sequence 
var sequence = ee.List.sequence(0, numberOfIntervals); 

// mapping the sequence
sequence = sequence.map(function(num){
    num = ee.Number(num);
    var Start_interval = startDate.advance(num.multiply(interval), 'month');
    var End_interval = startDate.advance(num.add(1).multiply(interval), 'month');
    var subset = ndvi.filterDate(Start_interval,End_interval);
    return subset.max().set('system:time_start',Start_interval);
});

// converting list of max images to imagecollection 
var yearly = ee.ImageCollection.fromImages(sequence);


//stacked image
var stacked=yearly.toBands().updateMask(image)

// Make the training dataset.
var training = stacked.sample({
  region: geometry,
  scale: 10,
  numPixels: 5000
});


// Instantiate the clusterer and train it.
var clusterer = ee.Clusterer.wekaKMeans(10).train(training);

// Cluster the input using the trained clusterer.
var result = stacked.cluster(clusterer);

// Display the clusters with random colors.
Map.addLayer(result.randomVisualizer().clip(geometry), {}, 'clusters');

//spectral signatures
// Calculating number of intervals
var numberOfIntervals = 10

// Generating a sequence 
var sequence = ee.List.sequence(0, numberOfIntervals); 

// mapping the sequence
sequence = sequence.map(function(num){
    num = ee.Number(num);
 var ptScale = ee.Number(300);
 var c = stacked.mask(result.select('cluster').eq(num)) 
 .reproject('epsg:4326',null,ptScale).reduceRegion({reducer: ee.Reducer.mean(), 
 geometry: geometry,
  maxPixels: 1e13 });
    return ee.FeatureCollection(c);
});

//print(sequence)
 var asList = ee.List(sequence).map(function (pair) {
  return ee.Feature(null, pair);
});
var spectral_values=ee.FeatureCollection(asList)

//print(spectral_values)

Export.table.toDrive(spectral_values);

//Map.addLayer(stacked.clip(geometry))

//Map.addLayer(result)
//exporting
Export.image.toDrive({
  image: result.clip(geometry),
  description: 'v_1',
  fileNamePrefix: 'v_1',
  region: geometry,
  maxPixels:1e12,
  scale:10
  });
  
