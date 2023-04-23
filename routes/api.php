<?php

use App\Models\sms;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/sms', function (Request $request) {
    if(null !== $request->input('unprocessed')){
        $smss = sms::where('status', 0)->orderBy('created_at', 'ASC')->get();
    }else{
        $smss = sms::orderBy('created_at', 'ASC')->get();
    }
    $ids = array();
    foreach ($smss as $sm) {
        array_push($ids,$sm->id);
    }
    return $ids;
});


Route::get('/getSMS/{id}', function (int $id) {
    $sm = sms::find($id);
    return $sm;
});

Route::get('/procSMS/{id}', function (int $id) {
    $sm = sms::find($id);
    $sm->status = 1;
    $sm->save();
    return $sm;
});

Route::get('/setSuccess/{id}', function (int $id) {
    $sm = sms::find($id);
    $sm->status = 2;
    $sm->save();
    return $sm;
});

Route::get('/setFailed/{id}', function (int $id) {
    $sm = sms::find($id);
    $sm->status = -1;
    $sm->save();
    return $sm;
});

Route::post('/createSMS', function (Request $request) { 
    $sms = new sms;
    $sms->number = $request->input('number');
    $sms->content = $request->input('content');
    $sms->save();
    return $sms->id;
});


