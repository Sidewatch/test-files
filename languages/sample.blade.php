@extends('layouts.app')

@section('title', 'Orders')

@section('content')
    {{-- The orders table, newest first --}}
    <h1 class="text-xl">{{ __('Orders for :name', ['name' => $user->name]) }}</h1>

    @if ($orders->isEmpty())
        <p class="muted">No orders yet.</p>
    @else
        <table>
            @foreach ($orders as $order)
                <tr @class(['paid' => $order->isPaid(), 'late' => $order->isLate()])>
                    <td>{{ $order->number }}</td>
                    <td>{{ $order->total->format() }}</td>
                    <td>{!! $order->statusBadge() !!}</td>
                </tr>
            @endforeach
        </table>
        {{ $orders->links() }}
    @endif

    @php($count = $orders->count())
    @include('partials.summary', ['count' => $count])
@endsection
